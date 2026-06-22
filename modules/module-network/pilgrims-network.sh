#!/bin/bash
MODULE_NAME="network"
MODULE_VERSION="1.0"
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_DIR="$(cd "$MODULE_DIR/../.." && pwd)"

source "$SCRIPT_DIR/core/ui.sh"
source "$SCRIPT_DIR/core/utils.sh"

TARGET="$1"
shift

PROFILE="quick"
for arg in "$@"; do
    case $arg in
        --quick) PROFILE="quick" ;;
        --deep) PROFILE="deep" ;;
        --vuln) PROFILE="vuln" ;;
    esac
done

if [ -z "$TARGET" ]; then
    print_error "Target not specified"
    exit 1
fi

OUTPUT_DIR="$MODULE_DIR/reports/net_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTPUT_DIR"

print_phase_header "NET" "🌐 NETWORK SECURITY ASSESSMENT"
print_info "Target: $TARGET"
print_info "Profile: $PROFILE"
echo ""

if [ "$EUID" -ne 0 ]; then
    print_warning "Some features require root privileges"
fi

print_phase_header "1" "🔍 HOST DISCOVERY"
print_task "Scanning for live hosts"

if command -v nmap &> /dev/null; then
    sudo nmap -sn "$TARGET" -oG "$OUTPUT_DIR/hosts.txt" > /dev/null 2>&1
    HOSTS=$(grep "Status: Up" "$OUTPUT_DIR/hosts.txt" 2>/dev/null | wc -l)
    print_success "Found $HOSTS live hosts"
else
    print_error "nmap not installed"
    HOSTS=0
fi

print_phase_header "2" "🔌 PORT SCANNING"
print_task "Scanning open ports"

if command -v nmap &> /dev/null; then
    if [ "$PROFILE" = "quick" ]; then
        sudo nmap -F "$TARGET" -oN "$OUTPUT_DIR/ports.txt" > /dev/null 2>&1
    else
        sudo nmap -sS -sV -O -p- "$TARGET" -oN "$OUTPUT_DIR/ports.txt" > /dev/null 2>&1
    fi
    OPEN_PORTS=$(grep -c "open" "$OUTPUT_DIR/ports.txt" 2>/dev/null || echo "0")
    print_success "Found $OPEN_PORTS open ports"
else
    print_error "nmap not installed"
    OPEN_PORTS=0
fi

print_phase_header "3" "🔧 SERVICE ENUMERATION"
print_task "Enumerating services"

if command -v nmap &> /dev/null; then
    sudo nmap -sC "$TARGET" -oN "$OUTPUT_DIR/services.txt" > /dev/null 2>&1
    print_success "Service enumeration complete"
fi

if [ "$PROFILE" = "vuln" ] || [ "$PROFILE" = "deep" ]; then
    print_phase_header "4" "⚠️ VULNERABILITY SCANNING"
    print_task "Scanning for vulnerabilities"
    
    if command -v nmap &> /dev/null; then
        sudo nmap --script vuln "$TARGET" -oN "$OUTPUT_DIR/vulns.txt" > /dev/null 2>&1
        VULNS=$(grep -c "VULNERABLE" "$OUTPUT_DIR/vulns.txt" 2>/dev/null || echo "0")
        
        if [ $VULNS -gt 0 ]; then
            print_critical "Found $VULNS vulnerabilities"
        else
            print_success "No vulnerabilities detected"
        fi
    fi
fi

print_phase_header "5" "📊 GENERATING REPORT"

cat > "$OUTPUT_DIR/REPORT.md" << REPORT_EOF
# 🌐 Network Security Report

**Target:** $TARGET
**Date:** $(date)
**Profile:** $PROFILE

## Summary

- Live Hosts: $HOSTS
- Open Ports: $OPEN_PORTS
- Vulnerabilities: ${VULNS:-0}

## Live Hosts

$(grep "Status: Up" "$OUTPUT_DIR/hosts.txt" 2>/dev/null | awk '{print $2}' || echo "None")

## Open Ports

$(grep "open" "$OUTPUT_DIR/ports.txt" 2>/dev/null | head -20 || echo "None")

## Vulnerabilities

$(cat "$OUTPUT_DIR/vulns.txt" 2>/dev/null | grep "VULNERABLE" || echo "None found")
REPORT_EOF

print_success "Report: $OUTPUT_DIR/REPORT.md"
print_mission_complete "network" "$TARGET" "$OUTPUT_DIR" "0"
