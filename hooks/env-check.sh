#!/bin/bash
# Environment validation hook for Claude Code
# Ensures proper environment setup before code modifications

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[ENV-CHECK] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[ENV-WARN] $1${NC}"
}

error() {
    echo -e "${RED}[ENV-ERROR] $1${NC}"
}

# Check if in git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    warn "Not in a git repository"
    exit 0
fi

# Python environment checks
if [[ -f "requirements.txt" || -f "pyproject.toml" || -f "setup.py" || -f "Pipfile" ]]; then
    log "Python project detected"
    
    # Check virtual environment
    if [[ -z "$VIRTUAL_ENV" ]]; then
        warn "No virtual environment active"
        if [[ -d ".venv" ]]; then
            warn "Found .venv directory. Consider: source .venv/bin/activate"
        elif [[ -d "venv" ]]; then
            warn "Found venv directory. Consider: source venv/bin/activate"
        fi
    else
        log "Virtual environment active: $VIRTUAL_ENV"
    fi
    
    # Check Python version
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2)
        log "Python version: $PYTHON_VERSION"
    fi
fi

# Node.js environment checks
if [[ -f "package.json" ]]; then
    log "Node.js project detected"
    
    if [[ ! -d "node_modules" ]]; then
        warn "node_modules not found. Consider: npm install"
    fi
    
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version 2>&1)
        log "Node.js version: $NODE_VERSION"
    fi
fi

# Check disk space
DISK_USAGE=$(df -h . | tail -1 | awk '{print $5}' | sed 's/%//')
if [[ $DISK_USAGE -gt 90 ]]; then
    warn "Disk usage is ${DISK_USAGE}% - consider cleaning up"
fi

log "Environment checks completed"
exit 0