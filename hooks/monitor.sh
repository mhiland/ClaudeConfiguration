#!/bin/bash
# Hook monitoring and logging system for Claude Code
# Tracks hook performance, failures, and provides analytics

# Configuration
MONITOR_LOG_DIR="$HOME/.claude/logs/hooks"
MONITOR_ENABLED=${CLAUDE_HOOK_MONITOR:-true}
MONITOR_RETENTION_DAYS=${CLAUDE_HOOK_RETENTION:-30}
MONITOR_MAX_LOG_SIZE=${CLAUDE_HOOK_MAX_LOG_SIZE:-10485760}  # 10MB

# Ensure log directory exists
mkdir -p "$MONITOR_LOG_DIR"

# Function to log hook event
log_hook_event() {
    local hook_name="$1"
    local event_type="$2"    # start, success, failure, bypass, brake
    local file_path="$3"
    local duration_ms="$4"
    local details="$5"
    
    if [[ "$MONITOR_ENABLED" != "true" ]]; then
        return 0
    fi
    
    local timestamp=$(date -Iseconds)
    local log_file="$MONITOR_LOG_DIR/${hook_name}.jsonl"
    
    # Create log entry
    local log_entry=$(cat << EOF
{
  "timestamp": "$timestamp",
  "hook": "$hook_name",
  "event": "$event_type",
  "file": "$file_path",
  "duration_ms": $duration_ms,
  "details": "$details",
  "pid": $$,
  "session_id": "${CLAUDE_SESSION_ID:-unknown}"
}
EOF
)
    
    # Append to log file
    echo "$log_entry" >> "$log_file"
    
    # Rotate log if too large
    if [[ -f "$log_file" && $(stat -c%s "$log_file" 2>/dev/null || echo 0) -gt $MONITOR_MAX_LOG_SIZE ]]; then
        rotate_log "$log_file"
    fi
}

# Function to rotate log file
rotate_log() {
    local log_file="$1"
    local backup_file="${log_file}.$(date +%Y%m%d_%H%M%S)"
    
    mv "$log_file" "$backup_file"
    gzip "$backup_file" 2>/dev/null || true
    
    echo "[MONITOR] Rotated log file: $log_file -> $backup_file.gz" >&2
}

# Function to cleanup old logs
cleanup_old_logs() {
    if [[ "$MONITOR_ENABLED" != "true" ]]; then
        return 0
    fi
    
    find "$MONITOR_LOG_DIR" -name "*.jsonl.gz" -mtime +$MONITOR_RETENTION_DAYS -delete 2>/dev/null || true
    find "$MONITOR_LOG_DIR" -name "*.jsonl.*" -mtime +$MONITOR_RETENTION_DAYS -delete 2>/dev/null || true
}

# Function to get hook statistics
get_hook_stats() {
    local hook_name="$1"
    local days="${2:-7}"
    local log_file="$MONITOR_LOG_DIR/${hook_name}.jsonl"
    
    if [[ ! -f "$log_file" ]]; then
        echo "No data available for $hook_name"
        return 1
    fi
    
    local since_date=$(date -d "$days days ago" -Iseconds)
    
    # Basic statistics
    local total_events=$(jq -r "select(.timestamp >= \"$since_date\")" "$log_file" | wc -l)
    local failures=$(jq -r "select(.timestamp >= \"$since_date\" and .event == \"failure\")" "$log_file" | wc -l)
    local successes=$(jq -r "select(.timestamp >= \"$since_date\" and .event == \"success\")" "$log_file" | wc -l)
    local bypasses=$(jq -r "select(.timestamp >= \"$since_date\" and .event == \"bypass\")" "$log_file" | wc -l)
    local brakes=$(jq -r "select(.timestamp >= \"$since_date\" and .event == \"brake\")" "$log_file" | wc -l)
    
    # Calculate success rate
    local success_rate=0
    if [[ $((successes + failures)) -gt 0 ]]; then
        success_rate=$(echo "scale=2; $successes * 100 / ($successes + $failures)" | bc 2>/dev/null || echo "0")
    fi
    
    # Average duration
    local avg_duration=$(jq -r "select(.timestamp >= \"$since_date\" and .duration_ms > 0) | .duration_ms" "$log_file" | awk '{sum+=$1; count++} END {if(count>0) print sum/count; else print 0}')
    
    cat << EOF
{
  "hook": "$hook_name",
  "period_days": $days,
  "total_events": $total_events,
  "successes": $successes,
  "failures": $failures,
  "bypasses": $bypasses,
  "emergency_brakes": $brakes,
  "success_rate": $success_rate,
  "avg_duration_ms": ${avg_duration:-0}
}
EOF
}

# Function to generate hook report
generate_hook_report() {
    local days="${1:-7}"
    local report_file="$MONITOR_LOG_DIR/report_$(date +%Y%m%d_%H%M%S).json"
    
    echo "{" > "$report_file"
    echo "  \"generated\": \"$(date -Iseconds)\"," >> "$report_file"
    echo "  \"period_days\": $days," >> "$report_file"
    echo "  \"hooks\": [" >> "$report_file"
    
    local first=true
    for log_file in "$MONITOR_LOG_DIR"/*.jsonl; do
        if [[ -f "$log_file" ]]; then
            local hook_name=$(basename "$log_file" .jsonl)
            [[ "$first" == "false" ]] && echo "    ," >> "$report_file"
            get_hook_stats "$hook_name" "$days" | sed 's/^/    /' >> "$report_file"
            first=false
        fi
    done
    
    echo "  ]" >> "$report_file"
    echo "}" >> "$report_file"
    
    echo "Report generated: $report_file"
}

# Function to check hook health
check_hook_health() {
    local hook_name="$1"
    local alert_threshold="${2:-80}"  # Alert if success rate below this percentage
    
    local stats=$(get_hook_stats "$hook_name" 1)
    local success_rate=$(echo "$stats" | jq -r '.success_rate // 0')
    local emergency_brakes=$(echo "$stats" | jq -r '.emergency_brakes // 0')
    
    # Check for low success rate
    if [[ $(echo "$success_rate < $alert_threshold" | bc) -eq 1 ]]; then
        echo "WARNING: $hook_name success rate is $success_rate% (threshold: $alert_threshold%)" >&2
        return 1
    fi
    
    # Check for emergency brakes
    if [[ $emergency_brakes -gt 0 ]]; then
        echo "WARNING: $hook_name has $emergency_brakes emergency brake(s) active" >&2
        return 1
    fi
    
    echo "Hook $hook_name is healthy (success rate: $success_rate%)"
    return 0
}

# Function to export logs for external analysis
export_logs() {
    local hook_name="$1"
    local format="${2:-json}"
    local days="${3:-7}"
    local output_file="$MONITOR_LOG_DIR/${hook_name}_export_$(date +%Y%m%d_%H%M%S).$format"
    
    local log_file="$MONITOR_LOG_DIR/${hook_name}.jsonl"
    if [[ ! -f "$log_file" ]]; then
        echo "No data available for $hook_name"
        return 1
    fi
    
    local since_date=$(date -d "$days days ago" -Iseconds)
    
    if [[ "$format" == "csv" ]]; then
        echo "timestamp,hook,event,file,duration_ms,details" > "$output_file"
        jq -r "select(.timestamp >= \"$since_date\") | [.timestamp, .hook, .event, .file, .duration_ms, .details] | @csv" "$log_file" >> "$output_file"
    else
        jq -r "select(.timestamp >= \"$since_date\")" "$log_file" > "$output_file"
    fi
    
    echo "Exported logs to: $output_file"
}

# Run cleanup on script load
cleanup_old_logs

# Function to start monitoring session
start_monitoring() {
    local hook_name="$1"
    local file_path="$2"
    
    export HOOK_START_TIME=$(date +%s%3N)
    log_hook_event "$hook_name" "start" "$file_path" 0 "Hook execution started"
}

# Function to end monitoring session
end_monitoring() {
    local hook_name="$1"
    local file_path="$2"
    local result="$3"  # success, failure, bypass
    local details="$4"
    
    local end_time=$(date +%s%3N)
    local duration=$((end_time - ${HOOK_START_TIME:-$end_time}))
    
    log_hook_event "$hook_name" "$result" "$file_path" "$duration" "$details"
}