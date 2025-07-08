#!/bin/bash
# Hook status and monitoring utility
# Usage: ./hook-status.sh [command] [options]

# Source monitoring utilities
source ~/.claude/hooks/monitor.sh
source ~/.claude/hooks/debounce.sh

# Function to display help
show_help() {
    cat << EOF
Hook Status and Monitoring Utility

Usage: $0 [command] [options]

Commands:
  status [hook]              Show current status of hooks
  stats [hook] [days]        Show statistics for hook (default: 7 days)
  report [days]              Generate comprehensive report
  health [hook]              Check hook health
  brake [hook] [minutes]     Manually trigger emergency brake
  reset [hook]               Reset failure count and emergency brake
  export [hook] [format]     Export logs (json/csv)
  monitor [hook]             Real-time monitoring
  list                       List all available hooks

Options:
  -h, --help                 Show this help message
  -v, --verbose              Verbose output
  -q, --quiet                Quiet mode (errors only)

Examples:
  $0 status                  # Show status of all hooks
  $0 stats quality-check     # Show 7-day stats for quality-check
  $0 health security-check   # Check health of security-check hook
  $0 brake quality-check 30  # Trigger 30-minute emergency brake
  $0 reset quality-check     # Reset quality-check failures
  $0 export quality-check csv # Export quality-check logs to CSV
EOF
}

# Function to show hook status
show_status() {
    local hook_name="$1"
    
    if [[ -n "$hook_name" ]]; then
        # Show status for specific hook
        echo "=== Status for $hook_name ==="
        
        # Check if debounce is active
        local debounce_file="/tmp/.claude_hooks/${hook_name}.lock"
        if [[ -f "$debounce_file" ]]; then
            local last_run=$(stat -c%Y "$debounce_file" 2>/dev/null || echo 0)
            local current_time=$(date +%s)
            local time_diff=$((current_time - last_run))
            
            if [[ $time_diff -lt 2 ]]; then
                echo "Debounce: ACTIVE (${time_diff}s remaining)"
            else
                echo "Debounce: INACTIVE"
            fi
        else
            echo "Debounce: INACTIVE"
        fi
        
        # Check emergency brake status
        local brake_status=$(get_emergency_brake_status "$hook_name")
        if [[ "$brake_status" == "active:"* ]]; then
            local remaining_seconds=${brake_status#active:}
            local remaining_minutes=$((remaining_seconds / 60))
            echo "Emergency Brake: ACTIVE (${remaining_minutes}m remaining)"
        elif [[ "$brake_status" == "expired" ]]; then
            echo "Emergency Brake: EXPIRED (cleaning up)"
        else
            echo "Emergency Brake: INACTIVE"
        fi
        
        # Show recent activity
        echo ""
        echo "Recent Activity:"
        get_hook_stats "$hook_name" 1
        
    else
        # Show status for all hooks
        echo "=== Hook Status Overview ==="
        
        for hook_file in ~/.claude/hooks/*.sh; do
            if [[ -f "$hook_file" ]]; then
                local hook_name=$(basename "$hook_file" .sh)
                
                # Skip utility scripts
                if [[ "$hook_name" =~ ^(debounce|monitor|hook-status)$ ]]; then
                    continue
                fi
                
                echo ""
                echo "Hook: $hook_name"
                show_status "$hook_name"
                echo "---"
            fi
        done
    fi
}

# Function to show real-time monitoring
monitor_hook() {
    local hook_name="$1"
    local log_file="$HOME/.claude/logs/hooks/${hook_name}.jsonl"
    
    if [[ ! -f "$log_file" ]]; then
        echo "No log file found for $hook_name"
        return 1
    fi
    
    echo "Monitoring $hook_name (Press Ctrl+C to stop)"
    echo "=== Real-time Hook Events ==="
    
    tail -f "$log_file" | while read -r line; do
        local timestamp=$(echo "$line" | jq -r '.timestamp')
        local event=$(echo "$line" | jq -r '.event')
        local file=$(echo "$line" | jq -r '.file')
        local duration=$(echo "$line" | jq -r '.duration_ms')
        
        printf "[%s] %s: %s" "$timestamp" "$event" "$file"
        if [[ "$duration" != "null" && "$duration" != "0" ]]; then
            printf " (${duration}ms)"
        fi
        echo ""
    done
}

# Function to list available hooks
list_hooks() {
    echo "Available hooks:"
    echo ""
    
    for hook_file in ~/.claude/hooks/*.sh; do
        if [[ -f "$hook_file" ]]; then
            local hook_name=$(basename "$hook_file" .sh)
            
            # Skip utility scripts
            if [[ "$hook_name" =~ ^(debounce|monitor|hook-status)$ ]]; then
                continue
            fi
            
            echo "  $hook_name"
            
            # Show brief description if available
            local description=$(head -5 "$hook_file" | grep -o '# .*' | tail -1 | sed 's/^# //')
            if [[ -n "$description" ]]; then
                echo "    $description"
            fi
            echo ""
        fi
    done
}

# Function to reset hook
reset_hook() {
    local hook_name="$1"
    
    echo "Resetting $hook_name..."
    
    # Reset debounce and failures
    reset_debounce "$hook_name"
    
    # Log the reset
    log_hook_event "$hook_name" "reset" "" 0 "Manually reset by user"
    
    echo "Reset complete for $hook_name"
}

# Main command processing
case "$1" in
    "status")
        show_status "$2"
        ;;
    "stats")
        get_hook_stats "$2" "${3:-7}"
        ;;
    "report")
        generate_hook_report "${2:-7}"
        ;;
    "health")
        check_hook_health "$2"
        ;;
    "brake")
        trigger_emergency_brake "$2" "${3:-10}"
        ;;
    "reset")
        reset_hook "$2"
        ;;
    "export")
        export_logs "$2" "${3:-json}" "${4:-7}"
        ;;
    "monitor")
        monitor_hook "$2"
        ;;
    "list")
        list_hooks
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac