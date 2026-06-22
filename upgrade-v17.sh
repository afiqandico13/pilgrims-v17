#!/bin/bash
# ============================================================================
# PILGRIMS v17.0 - TOP 5 UPGRADES
# Resume Scan + Comparative + Attack Path + MITRE + Parallel
# ============================================================================

echo "🚀 PILGRIMS v17.0 - Installing Top 5 Upgrades..."
echo "═══════════════════════════════════════════════════"

# ============================================================================
# UPGRADE 1: RESUME SCAN SYSTEM
# ============================================================================
echo ""
echo "[1/5] 🔄 Installing Resume Scan System..."

cat > core/resume.sh << 'RESUMEEOF'
#!/bin/bash
# ============================================================================
# RESUME SCAN SYSTEM - Save & Restore Scan State
# ============================================================================

# Save current scan state
save_scan_state() {
    local module=$1
    local target=$2
    local phase=$3
    local output_dir=$4
    local state_file="$output_dir/.state.json"
    
    cat > "$state_file" << EOF
{
  "module": "$module",
  "target": "$target",
  "phase": "$phase",
  "timestamp": $(date +%s),
  "output_dir": "$output_dir",
  "status": "paused"
}
EOF
    
    print_success "State saved: Phase $phase"
}

# Load scan state
load_scan_state() {
    local state_file=$1
    
    if [ ! -f "$state_file" ]; then
        print_error "No state file found"
        return 1
    fi
    
    local module=$(jq -r '.module' "$state_file")
    local target=$(jq -r '.target' "$state_file")
    local phase=$(jq -r '.phase' "$state_file")
    local output_dir=$(jq -r '.output_dir' "$state_file")
    
    echo "$module|$target|$phase|$output_dir"
}

# List resumable scans
list_resumable_scans() {
    print_epic_banner
    echo -e "    ${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "    ${CYAN}║              🔄 RESUMABLE SCANS                               ║${NC}"
    echo -e "    ${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    local count=0
    for state_file in $(find modules/*/reports -name ".state.json" 2>/dev/null); do
        local module=$(jq -r '.module' "$state_file")
        local target=$(jq -r '.target' "$state_file")
        local phase=$(jq -r '.phase' "$state_file")
        local timestamp=$(jq -r '.timestamp' "$state_file")
        local date=$(date -d @$timestamp '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date -r $timestamp '+%Y-%m-%d %H:%M:%S' 2>/dev/null)
        local dir=$(dirname "$state_file")
        
        echo -e "    ${GREEN}[$count]${NC} Module: ${BOLD}$module${NC}"
        echo -e "        Target: $target"
        echo -e "        Phase: $phase"
        echo -e "        Saved: $date"
        echo -e "        Dir: $dir"
        echo ""
        ((count++))
    done
    
    if [ $count -eq 0 ]; then
        echo -e "    ${YELLOW}⚠ No resumable scans found${NC}"
    fi
}

# Resume a scan
resume_scan() {
    local scan_dir=$1
    
    if [ ! -d "$scan_dir" ]; then
        print_error "Scan directory not found: $scan_dir"
        return 1
    fi
    
    local state_file="$scan_dir/.state.json"
    if [ ! -f "$state_file" ]; then
        print_error "No state file in: $scan_dir"
        return 1
    fi
    
    local state=$(load_scan_state "$state_file")
    IFS='|' read -r module target phase output_dir <<< "$state"
    
    print_epic_banner
    echo -e "    ${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "    ${CYAN}║              🔄 RESUMING SCAN                                 ║${NC}"
    echo -e "    ${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "    ${BOLD}Module:${NC}    $module"
    echo -e "    ${BOLD}Target:${NC}    $target"
    echo -e "    ${BOLD}Phase:${NC}     $phase"
    echo -e "    ${BOLD}Output:${NC}    $output_dir"
    echo ""
    echo -e "    ${GREEN}✓ Resuming from phase $phase...${NC}"
    echo ""
    
    # Update state to running
    jq '.status = "running"' "$state_file" > "$state_file.tmp" && mv "$state_file.tmp" "$state_file"
    
    # Execute module from resume point
    local module_script="modules/module-$module/pilgrims-$module.sh"
    if [ -f "$module_script" ]; then
        "$module_script" "$target" --resume-from="$phase" --output-dir="$output_dir"
        
        # Mark as complete
        jq '.status = "completed"' "$state_file" > "$state_file.tmp" && mv "$state_file.tmp" "$state_file"
        
        print_success "Scan resumed and completed!"
    else
        print_error "Module script not found: $module_script"
    fi
}
RESUMEEOF

chmod +x core/resume.sh
echo "   ✅ Resume Scan System installed"

# ============================================================================
# UPGRADE 2: COMPARATIVE ANALYSIS
# ============================================================================
echo ""
echo "[2/5] 📊 Installing Comparative Analysis..."

cat > core/compare.sh << 'COMPAREEOF'
#!/bin/bash
# ============================================================================
# COMPARATIVE ANALYSIS - Compare Scans Over Time
# ============================================================================

compare_scans() {
    local module=$1
    local target=$2
    
    print_epic_banner
    echo -e "    ${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "    ${CYAN}║              📊 COMPARATIVE ANALYSIS                          ║${NC}"
    echo -e "    ${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Find all scans for this module+target
    local scans=($(find "modules/module-$module/reports" -maxdepth 1 -type d -name "${module}_*" 2>/dev/null | sort -r))
    
    if [ ${#scans[@]} -lt 2 ]; then
        print_warning "Need at least 2 scans to compare"
        print_info "Found: ${#scans[@]} scan(s)"
        return 1
    fi
    
    local latest="${scans[0]}"
    local previous="${scans[1]}"
    
    echo -e "    ${BOLD}Latest:${NC}   $(basename $latest)"
    echo -e "    ${BOLD}Previous:${NC} $(basename $previous)"
    echo ""
    
    # Count findings in each
    local latest_crit=$(find "$latest" -name "*.txt" -exec grep -l "\[CRITICAL\]" {} + 2>/dev/null | wc -l)
    local latest_high=$(find "$latest" -name "*.txt" -exec grep -l "\[HIGH\]" {} + 2>/dev/null | wc -l)
    local latest_med=$(find "$latest" -name "*.txt" -exec grep -l "\[MEDIUM\]" {} + 2>/dev/null | wc -l)
    local latest_low=$(find "$latest" -name "*.txt" -exec grep -l "\[LOW\]" {} + 2>/dev/null | wc -l)
    
    local prev_crit=$(find "$previous" -name "*.txt" -exec grep -l "\[CRITICAL\]" {} + 2>/dev/null | wc -l)
    local prev_high=$(find "$previous" -name "*.txt" -exec grep -l "\[HIGH\]" {} + 2>/dev/null | wc -l)
    local prev_med=$(find "$previous" -name "*.txt" -exec grep -l "\[MEDIUM\]" {} + 2>/dev/null | wc -l)
    local prev_low=$(find "$previous" -name "*.txt" -exec grep -l "\[LOW\]" {} + 2>/dev/null | wc -l)
    
    # Calculate changes
    local crit_change=$((latest_crit - prev_crit))
    local high_change=$((latest_high - prev_high))
    local med_change=$((latest_med - prev_med))
    local low_change=$((latest_low - prev_low))
    
    # Display comparison table
    echo -e "    ${CYAN}┌──────────────────────────────────────────────────────────────┐${NC}"
    echo -e "    ${CYAN}│${NC} ${BOLD}FINDINGS COMPARISON${NC}                                          ${CYAN}│${NC}"
    echo -e "    ${CYAN}├──────────────────────────────────────────────────────────────┤${NC}"
    printf "    ${CYAN}│${NC} ${BOLD}%-12s %-12s %-12s %-12s${NC} ${CYAN}│${NC}\n" "Severity" "Previous" "Current" "Change"
    echo -e "    ${CYAN}├──────────────────────────────────────────────────────────────┤${NC}"
    
    # Critical row
    local crit_icon="➖"
    local crit_color="$WHITE"
    if [ $crit_change -lt 0 ]; then crit_icon="✅"; crit_color="$GREEN"; 
    elif [ $crit_change -gt 0 ]; then crit_icon="⚠️"; crit_color="$RED"; fi
    
    printf "    ${CYAN}│${NC} ${RED}%-12s${NC} %-12s %-12s ${crit_color}%-12s${NC} ${CYAN}│${NC}\n" \
        "Critical" "$prev_crit" "$latest_crit" "$crit_icon $crit_change"
    
    # High row
    local high_icon="➖"
    local high_color="$WHITE"
    if [ $high_change -lt 0 ]; then high_icon="✅"; high_color="$GREEN"; 
    elif [ $high_change -gt 0 ]; then high_icon="⚠️"; high_color="$RED"; fi
    
    printf "    ${CYAN}│${NC} ${YELLOW}%-12s${NC} %-12s %-12s ${high_color}%-12s${NC} ${CYAN}│${NC}\n" \
        "High" "$prev_high" "$latest_high" "$high_icon $high_change"
    
    # Medium row
    local med_icon="➖"
    local med_color="$WHITE"
    if [ $med_change -lt 0 ]; then med_icon="✅"; med_color="$GREEN"; 
    elif [ $med_change -gt 0 ]; then med_icon="⚠️"; med_color="$YELLOW"; fi
    
    printf "    ${CYAN}│${NC} ${BLUE}%-12s${NC} %-12s %-12s ${med_color}%-12s${NC} ${CYAN}│${NC}\n" \
        "Medium" "$prev_med" "$latest_med" "$med_icon $med_change"
    
    # Low row
    local low_icon="➖"
    local low_color="$WHITE"
    if [ $low_change -lt 0 ]; then low_icon="✅"; low_color="$GREEN"; 
    elif [ $low_change -gt 0 ]; then low_icon="⚠️"; low_color="$YELLOW"; fi
    
    printf "    ${CYAN}│${NC} ${CYAN}%-12s${NC} %-12s %-12s ${low_color}%-12s${NC} ${CYAN}│${NC}\n" \
        "Low" "$prev_low" "$latest_low" "$low_icon $low_change"
    
    echo -e "    ${CYAN}└──────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    # Overall assessment
    local total_change=$((crit_change + high_change + med_change + low_change))
    if [ $total_change -lt 0 ]; then
        echo -e "    ${GREEN}${BOLD}✅ Security posture IMPROVED ($total_change fewer findings)${NC}"
    elif [ $total_change -gt 0 ]; then
        echo -e "    ${RED}${BOLD}⚠️  Security posture DEGRADED (+$total_change new findings)${NC}"
    else
        echo -e "    ${YELLOW}${BOLD}➖ Security posture UNCHANGED${NC}"
    fi
    echo ""
    
    # Find new findings (in latest but not in previous)
    echo -e "    ${BOLD}🆕 New Findings:${NC}"
    comm -23 <(find "$latest" -name "*.txt" -exec grep -hE "\[CRITICAL\]|\[HIGH\]" {} + 2>/dev/null | sort -u) \
             <(find "$previous" -name "*.txt" -exec grep -hE "\[CRITICAL\]|\[HIGH\]" {} + 2>/dev/null | sort -u) | \
        head -10 | while read -r line; do
            echo -e "    ${RED}+${NC} $line"
        done
    echo ""
    
    # Find fixed findings (in previous but not in latest)
    echo -e "    ${BOLD}✅ Fixed Findings:${NC}"
    comm -13 <(find "$latest" -name "*.txt" -exec grep -hE "\[CRITICAL\]|\[HIGH\]" {} + 2>/dev/null | sort -u) \
             <(find "$previous" -name "*.txt" -exec grep -hE "\[CRITICAL\]|\[HIGH\]" {} + 2>/dev/null | sort -u) | \
        head -10 | while read -r line; do
            echo -e "    ${GREEN}-${NC} $line"
        done
    echo ""
    
    # Save comparison report
    local compare_dir="$latest/compare"
    mkdir -p "$compare_dir"
    cat > "$compare_dir/comparison.md" << EOF
# 📊 Comparative Analysis Report

**Module:** $module
**Target:** $target
**Latest Scan:** $(basename $latest)
**Previous Scan:** $(basename $previous)
**Date:** $(date)

## Summary

| Severity | Previous | Current | Change |
|----------|----------|---------|--------|
| Critical | $prev_crit | $latest_crit | $crit_change |
| High | $prev_high | $latest_high | $high_change |
| Medium | $prev_med | $latest_med | $med_change |
| Low | $prev_low | $latest_low | $low_change |

## Assessment

Total change: $total_change findings

## New Findings

$(comm -23 <(find "$latest" -name "*.txt" -exec grep -hE "\[CRITICAL\]|\[HIGH\]" {} + 2>/dev/null | sort -u) \
             <(find "$previous" -name "*.txt" -exec grep -hE "\[CRITICAL\]|\[HIGH\]" {} + 2>/dev/null | sort -u))

## Fixed Findings

$(comm -13 <(find "$latest" -name "*.txt" -exec grep -hE "\[CRITICAL\]|\[HIGH\]" {} + 2>/dev/null | sort -u) \
             <(find "$previous" -name "*.txt" -exec grep -hE "\[CRITICAL\]|\[HIGH\]" {} + 2>/dev/null | sort -u))
EOF
    
    print_success "Comparison report saved: $compare_dir/comparison.md"
}
COMPAREEOF

chmod +x core/compare.sh
echo "   ✅ Comparative Analysis installed"

# ============================================================================
# UPGRADE 3: ATTACK PATH MAPPER
# ============================================================================
echo ""
echo "[3/5] 🗺️  Installing Attack Path Mapper..."

cat > core/attack_path.sh << 'ATTACKEOF'
#!/bin/bash
# ============================================================================
# ATTACK PATH MAPPER - Visualize Attack Chains
# ============================================================================

map_attack_paths() {
    local output_dir=$1
    
    print_epic_banner
    echo -e "    ${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "    ${CYAN}║              🗺️  ATTACK PATH MAPPING                          ║${NC}"
    echo -e "    ${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Analyze findings
    local sqli=$(find "$output_dir" -path "*/sqli/*" -name "*.txt" -exec grep -l "\[CRITICAL\]\|\[HIGH\]" {} + 2>/dev/null | wc -l)
    local xss=$(find "$output_dir" -path "*/xss/*" -name "*.txt" -exec grep -l "\[CRITICAL\]\|\[HIGH\]" {} + 2>/dev/null | wc -l)
    local ssrf=$(find "$output_dir" -path "*/ssrf/*" -name "*.txt" -exec grep -l "\[CRITICAL\]\|\[HIGH\]" {} + 2>/dev/null | wc -l)
    local idor=$(find "$output_dir" -path "*/idor/*" -name "*.txt" -exec grep -l "\[CRITICAL\]\|\[HIGH\]" {} + 2>/dev/null | wc -l)
    local auth=$(find "$output_dir" -path "*/auth*" -name "*.txt" -exec grep -l "\[CRITICAL\]\|\[HIGH\]" {} + 2>/dev/null | wc -l)
    local cloud=$(find "$output_dir" -path "*/cloud/*" -name "*.txt" -exec grep -l "\[CRITICAL\]\|\[HIGH\]" {} + 2>/dev/null | wc -l)
    
    echo -e "    ${BOLD}📊 Vulnerability Detection:${NC}"
    echo -e "    💉 SQL Injection:    $([ $sqli -gt 0 ] && echo "${RED}$sqli FOUND${NC}" || echo "${GREEN}None${NC}")"
    echo -e "    ⚡ XSS:              $([ $xss -gt 0 ] && echo "${RED}$xss FOUND${NC}" || echo "${GREEN}None${NC}")"
    echo -e "    🎯 SSRF:             $([ $ssrf -gt 0 ] && echo "${RED}$ssrf FOUND${NC}" || echo "${GREEN}None${NC}")"
    echo -e "    🔓 IDOR:             $([ $idor -gt 0 ] && echo "${RED}$idor FOUND${NC}" || echo "${GREEN}None${NC}")"
    echo -e "    🔐 Auth Issues:      $([ $auth -gt 0 ] && echo "${RED}$auth FOUND${NC}" || echo "${GREEN}None${NC}")"
    echo -e "    ☁️  Cloud Issues:     $([ $cloud -gt 0 ] && echo "${RED}$cloud FOUND${NC}" || echo "${GREEN}None${NC}")"
    echo ""
    
    echo -e "    ${BOLD}🗺️  Identified Attack Paths:${NC}"
    echo -e "    ${DIM}───────────────────────────────────────────────────────────────${NC}"
    echo ""
    
    local path_count=0
    
    # Path 1: SQLi → Database → Data Exfiltration
    if [ $sqli -gt 0 ]; then
        ((path_count++))
        echo -e "    ${RED}PATH $path_count: SQL Injection Chain${NC}"
        echo -e "    ${YELLOW}[SQL_INJECTION]${NC} ──→ ${YELLOW}[DATABASE_ACCESS]${NC} ──→ ${RED}[DATA_EXFILTRATION]${NC} ──→ ${RED}🎯 COMPROMISE${NC}"
        echo -e "    ${DIM}Impact: Complete database takeover, sensitive data theft${NC}"
        echo -e "    ${DIM}CVSS: 9.8 (Critical)${NC}"
        echo ""
    fi
    
    # Path 2: XSS → Session Hijack → Account Takeover
    if [ $xss -gt 0 ]; then
        ((path_count++))
        echo -e "    ${RED}PATH $path_count: XSS Chain${NC}"
        echo -e "    ${YELLOW}[XSS]${NC} ──→ ${YELLOW}[SESSION_HIJACK]${NC} ──→ ${RED}[ACCOUNT_TAKEOVER]${NC} ──→ ${RED}🎯 COMPROMISE${NC}"
        echo -e "    ${DIM}Impact: User account compromise, data theft${NC}"
        echo -e "    ${DIM}CVSS: 8.5 (High)${NC}"
        echo ""
    fi
    
    # Path 3: SSRF → Cloud Metadata → Full Compromise
    if [ $ssrf -gt 0 ] && [ $cloud -gt 0 ]; then
        ((path_count++))
        echo -e "    ${RED}PATH $path_count: SSRF + Cloud Chain${NC}"
        echo -e "    ${YELLOW}[SSRF]${NC} ──→ ${YELLOW}[CLOUD_METADATA]${NC} ──→ ${RED}[CREDENTIAL_EXTRACT]${NC} ──→ ${RED}🎯 FULL_COMPROMISE${NC}"
        echo -e "    ${DIM}Impact: Complete cloud infrastructure takeover${NC}"
        echo -e "    ${DIM}CVSS: 10.0 (Critical)${NC}"
        echo ""
    elif [ $ssrf -gt 0 ]; then
        ((path_count++))
        echo -e "    ${RED}PATH $path_count: SSRF Chain${NC}"
        echo -e "    ${YELLOW}[SSRF]${NC} ──→ ${YELLOW}[INTERNAL_NETWORK]${NC} ──→ ${RED}[SERVICE_DISCOVERY]${NC} ──→ ${RED}🎯 LATERAL_MOVEMENT${NC}"
        echo -e "    ${DIM}Impact: Internal network access, service enumeration${NC}"
        echo -e "    ${DIM}CVSS: 8.0 (High)${NC}"
        echo ""
    fi
    
    # Path 4: IDOR → Privilege Escalation → Admin Access
    if [ $idor -gt 0 ]; then
        ((path_count++))
        echo -e "    ${RED}PATH $path_count: IDOR Chain${NC}"
        echo -e "    ${YELLOW}[IDOR]${NC} ──→ ${YELLOW}[PRIVILEGE_ESCALATION]${NC} ──→ ${RED}[ADMIN_ACCESS]${NC} ──→ ${RED}🎯 FULL_CONTROL${NC}"
        echo -e "    ${DIM}Impact: Unauthorized access to other users' data${NC}"
        echo -e "    ${DIM}CVSS: 7.5 (High)${NC}"
        echo ""
    fi
    
    # Path 5: Auth Bypass → Admin Panel → Full Control
    if [ $auth -gt 0 ]; then
        ((path_count++))
        echo -e "    ${RED}PATH $path_count: Authentication Bypass Chain${NC}"
        echo -e "    ${YELLOW}[AUTH_BYPASS]${NC} ──→ ${YELLOW}[ADMIN_PANEL]${NC} ──→ ${RED}[CONFIG_CHANGE]${NC} ──→ ${RED}🎯 FULL_CONTROL${NC}"
        echo -e "    ${DIM}Impact: Complete system compromise${NC}"
        echo -e "    ${DIM}CVSS: 9.5 (Critical)${NC}"
        echo ""
    fi
    
    # Path 6: Combined attack (if multiple vulns)
    if [ $sqli -gt 0 ] && [ $xss -gt 0 ] && [ $auth -gt 0 ]; then
        ((path_count++))
        echo -e "    ${RED}PATH $path_count: Advanced Multi-Vector Attack${NC}"
        echo -e "    ${YELLOW}[RECON]${NC} ──→ ${YELLOW}[XSS]${NC} ──→ ${YELLOW}[SESSION_HIJACK]${NC} ──→ ${YELLOW}[SQLI]${NC} ──→ ${RED}[DATA_EXFIL]${NC} ──→ ${RED}🎯 TOTAL_COMPROMISE${NC}"
        echo -e "    ${DIM}Impact: Complete system and data compromise${NC}"
        echo -e "    ${DIM}CVSS: 10.0 (Critical)${NC}"
        echo ""
    fi
    
    if [ $path_count -eq 0 ]; then
        echo -e "    ${GREEN}✅ No significant attack paths identified${NC}"
        echo -e "    ${DIM}Target appears to be well-secured${NC}"
    else
        echo -e "    ${DIM}───────────────────────────────────────────────────────────────${NC}"
        echo -e "    ${BOLD}Total Attack Paths Identified: $path_count${NC}"
    fi
    echo ""
    
    # Save attack path report
    local attack_dir="$output_dir/attack_paths"
    mkdir -p "$attack_dir"
    cat > "$attack_dir/attack_paths.md" << EOF
# 🗺️  Attack Path Analysis Report

**Date:** $(date)
**Output Directory:** $output_dir

## Vulnerability Detection

| Category | Count |
|----------|-------|
| SQL Injection | $sqli |
| XSS | $xss |
| SSRF | $ssrf |
| IDOR | $idor |
| Auth Issues | $auth |
| Cloud Issues | $cloud |

## Identified Attack Paths

**Total:** $path_count paths

### Path Analysis
$(if [ $sqli -gt 0 ]; then
echo "- **SQL Injection Chain**: SQLi → Database → Data Exfiltration (CVSS 9.8)"
fi
if [ $xss -gt 0 ]; then
echo "- **XSS Chain**: XSS → Session Hijack → Account Takeover (CVSS 8.5)"
fi
if [ $ssrf -gt 0 ]; then
echo "- **SSRF Chain**: SSRF → Internal Network → Service Discovery (CVSS 8.0)"
fi
if [ $idor -gt 0 ]; then
echo "- **IDOR Chain**: IDOR → Privilege Escalation → Admin Access (CVSS 7.5)"
fi
if [ $auth -gt 0 ]; then
echo "- **Auth Bypass Chain**: Auth Bypass → Admin Panel → Full Control (CVSS 9.5)"
fi)

## Recommendations

1. Address critical paths first (CVSS 9.0+)
2. Implement defense-in-depth
3. Regular penetration testing
4. Security monitoring and alerting
5. Incident response planning
EOF
    
    print_success "Attack path report saved: $attack_dir/attack_paths.md"
}
ATTACKEOF

chmod +x core/attack_path.sh
echo "   ✅ Attack Path Mapper installed"

# ============================================================================
# UPGRADE 4: MITRE ATT&CK MAPPING
# ============================================================================
echo ""
echo "[4/5] 🎯 Installing MITRE ATT&CK Mapping..."

cat > core/mitre.sh << 'MITREEOF'
#!/bin/bash
# ============================================================================
# MITRE ATT&CK MAPPING - Map Findings to ATT&CK Framework
# ============================================================================

map_to_mitre() {
    local output_dir=$1
    
    print_epic_banner
    echo -e "    ${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "    ${CYAN}║              🎯 MITRE ATT&CK MAPPING                          ║${NC}"
    echo -e "    ${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Define MITRE mappings
    declare -A MITRE_MAP=(
        ["sqli"]="T1190:Exploit Public-Facing Application"
        ["xss"]="T1189:Drive-by Compromise"
        ["ssrf"]="T1090:Connection Proxy"
        ["idor"]="T1078:Valid Accounts"
        ["cmdi"]="T1059:Command and Scripting Interpreter"
        ["xxe"]="T1190:Exploit Public-Facing Application"
        ["auth"]="T1078:Valid Accounts"
        ["cloud"]="T1580:Cloud Infrastructure Discovery"
        ["secrets"]="T1552:Unsecured Credentials"
        ["takeover"]="T1584:Compromise Infrastructure"
    )
    
    # Analyze findings
    echo -e "    ${BOLD}📊 MITRE ATT&CK Technique Mapping:${NC}"
    echo -e "    ${DIM}───────────────────────────────────────────────────────────────${NC}"
    echo ""
    
    local total_techniques=0
    
    for vuln in "${!MITRE_MAP[@]}"; do
        local count=$(find "$output_dir" -path "*/$vuln/*" -name "*.txt" -exec grep -l "\[CRITICAL\]\|\[HIGH\]\|\[MEDIUM\]" {} + 2>/dev/null | wc -l)
        
        if [ $count -gt 0 ]; then
            local mitre="${MITRE_MAP[$vuln]}"
            local technique=$(echo "$mitre" | cut -d: -f1)
            local name=$(echo "$mitre" | cut -d: -f2)
            
            echo -e "    ${RED}${technique}${NC} - ${BOLD}$name${NC}"
            echo -e "    ${DIM}Findings: $count${NC}"
            echo -e "    ${DIM}Source: $vuln${NC}"
            echo ""
            ((total_techniques++))
        fi
    done
    
    if [ $total_techniques -eq 0 ]; then
        echo -e "    ${GREEN}✅ No MITRE ATT&CK techniques mapped${NC}"
        echo -e "    ${DIM}Target shows good security posture${NC}"
    else
        echo -e "    ${DIM}───────────────────────────────────────────────────────────────${NC}"
        echo -e "    ${BOLD}Total ATT&CK Techniques Mapped: $total_techniques${NC}"
    fi
    echo ""
    
    # Display ATT&CK Navigator-style matrix
    echo -e "    ${BOLD}🗺️  ATT&CK Matrix View:${NC}"
    echo -e "    ${DIM}───────────────────────────────────────────────────────────────${NC}"
    echo ""
    
    # Initial Access
    echo -e "    ${BOLD}TA0001 - Initial Access${NC}"
    [ $(find "$output_dir" -path "*/sqli/*" -name "*.txt" 2>/dev/null | wc -l) -gt 0 ] && \
        echo -e "    ${RED}  └─ T1190: Exploit Public-Facing Application${NC}"
    [ $(find "$output_dir" -path "*/xss/*" -name "*.txt" 2>/dev/null | wc -l) -gt 0 ] && \
        echo -e "    ${RED}  └─ T1189: Drive-by Compromise${NC}"
    echo ""
    
    # Execution
    echo -e "    ${BOLD}TA0002 - Execution${NC}"
    [ $(find "$output_dir" -path "*/cmdi/*" -name "*.txt" 2>/dev/null | wc -l) -gt 0 ] && \
        echo -e "    ${RED}  └─ T1059: Command and Scripting Interpreter${NC}"
    echo ""
    
    # Persistence
    echo -e "    ${BOLD}TA0003 - Persistence${NC}"
    [ $(find "$output_dir" -path "*/auth/*" -name "*.txt" 2>/dev/null | wc -l) -gt 0 ] && \
        echo -e "    ${RED}  └─ T1078: Valid Accounts${NC}"
    echo ""
    
    # Credential Access
    echo -e "    ${BOLD}TA0006 - Credential Access${NC}"
    [ $(find "$output_dir" -path "*/secrets/*" -name "*.txt" 2>/dev/null | wc -l) -gt 0 ] && \
        echo -e "    ${RED}  └─ T1552: Unsecured Credentials${NC}"
    echo ""
    
    # Discovery
    echo -e "    ${BOLD}TA0007 - Discovery${NC}"
    [ $(find "$output_dir" -path "*/cloud/*" -name "*.txt" 2>/dev/null | wc -l) -gt 0 ] && \
        echo -e "    ${RED}  └─ T1580: Cloud Infrastructure Discovery${NC}"
    echo ""
    
    # Lateral Movement
    echo -e "    ${BOLD}TA0008 - Lateral Movement${NC}"
    [ $(find "$output_dir" -path "*/ssrf/*" -name "*.txt" 2>/dev/null | wc -l) -gt 0 ] && \
        echo -e "    ${RED}  └─ T1090: Connection Proxy${NC}"
    [ $(find "$output_dir" -path "*/idor/*" -name "*.txt" 2>/dev/null | wc -l) -gt 0 ] && \
        echo -e "    ${RED}  └─ T1078: Valid Accounts${NC}"
    echo ""
    
    # Save MITRE report
    local mitre_dir="$output_dir/mitre"
    mkdir -p "$mitre_dir"
    cat > "$mitre_dir/mitre_mapping.md" << EOF
# 🎯 MITRE ATT&CK Mapping Report

**Date:** $(date)
**Output Directory:** $output_dir

## Technique Mapping

| Technique ID | Name | Findings | Source |
|--------------|------|----------|--------|
$(for vuln in "${!MITRE_MAP[@]}"; do
    count=$(find "$output_dir" -path "*/$vuln/*" -name "*.txt" -exec grep -l "\[CRITICAL\]\|\[HIGH\]\|\[MEDIUM\]" {} + 2>/dev/null | wc -l)
    if [ $count -gt 0 ]; then
        mitre="${MITRE_MAP[$vuln]}"
        technique=$(echo "$mitre" | cut -d: -f1)
        name=$(echo "$mitre" | cut -d: -f2)
        echo "| $technique | $name | $count | $vuln |"
    fi
done)

## ATT&CK Tactics Covered

- **TA0001 - Initial Access**: Public-facing application exploits
- **TA0002 - Execution**: Command injection
- **TA0003 - Persistence**: Authentication bypass
- **TA0006 - Credential Access**: Exposed credentials
- **TA0007 - Discovery**: Cloud infrastructure discovery
- **TA0008 - Lateral Movement**: SSRF, IDOR

## Recommendations

1. Map findings to your organization's threat model
2. Prioritize based on ATT&CK technique severity
3. Implement detection rules for mapped techniques
4. Regular threat hunting based on ATT&CK coverage
5. Update security controls based on ATT&CK mappings

## References

- MITRE ATT&CK: https://attack.mitre.org/
- ATT&CK Navigator: https://mitre-attack.github.io/attack-navigator/
EOF
    
    print_success "MITRE mapping saved: $mitre_dir/mitre_mapping.md"
}
MITREEOF

chmod +x core/mitre.sh
echo "   ✅ MITRE ATT&CK Mapping installed"

# ============================================================================
# UPGRADE 5: PARALLEL SCANNING
# ============================================================================
echo ""
echo "[5/5] ⚡ Installing Parallel Scanning..."

cat > core/parallel.sh << 'PARALLELEOF'
#!/bin/bash
# ============================================================================
# PARALLEL SCANNING - Multi-threaded Scan Execution
# ============================================================================

parallel_scan() {
    local targets_file=$1
    local module=$2
    local threads=${3:-4}
    
    if [ ! -f "$targets_file" ]; then
        print_error "Targets file not found: $targets_file"
        return 1
    fi
    
    local total=$(wc -l < "$targets_file")
    
    print_epic_banner
    echo -e "    ${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "    ${CYAN}║              ⚡ PARALLEL SCANNING                             ║${NC}"
    echo -e "    ${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "    ${BOLD}Module:${NC}   $module"
    echo -e "    ${BOLD}Targets:${NC}  $total"
    echo -e "    ${BOLD}Threads:${NC}  $threads"
    echo ""
    
    local start_time=$(date +%s)
    local pids=()
    local results_dir="reports/parallel_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$results_dir"
    
    echo -e "    ${GREEN}🚀 Starting parallel scan...${NC}"
    echo ""
    
    local count=0
    while IFS= read -r target; do
        [ -z "$target" ] && continue
        [[ "$target" =~ ^# ]] && continue
        
        # Launch scan in background
        (
            ./pilgrims.sh --module=$module "$target" --quick > "$results_dir/${target//\//_}.log" 2>&1
            echo "$target: $?" > "$results_dir/${target//\//_}.status"
        ) &
        pids+=($!)
        ((count++))
        
        # Limit parallel threads
        if [ $count -ge $threads ]; then
            wait "${pids[0]}"
            pids=("${pids[@]:1}")
        fi
        
        echo -e "    ${CYAN}▶${NC} Launched: $target (PID: ${pids[-1]})"
        
    done < "$targets_file"
    
    # Wait for all remaining
    echo ""
    echo -e "    ${CYAN}⏳ Waiting for remaining scans to complete...${NC}"
    wait
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Analyze results
    local success=0
    local failed=0
    
    for status_file in "$results_dir"/*.status; do
        [ -f "$status_file" ] || continue
        local status=$(tail -1 "$status_file" | cut -d: -f2)
        if [ "$status" = "0" ]; then
            ((success++))
        else
            ((failed++))
        fi
    done
    
    echo ""
    echo -e "    ${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "    ${CYAN}║              📊 PARALLEL SCAN RESULTS                         ║${NC}"
    echo -e "    ${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "    ${BOLD}Total Targets:${NC}  $total"
    echo -e "    ${GREEN}✓ Successful:${NC}    $success"
    echo -e "    ${RED}✗ Failed:${NC}        $failed"
    echo -e "    ${BOLD}Duration:${NC}        ${duration}s"
    echo -e "    ${BOLD}Speed:${NC}           $(echo "scale=2; $total / $duration" | bc) targets/sec"
    echo ""
    
    # Save summary
    cat > "$results_dir/SUMMARY.md" << EOF
# ⚡ Parallel Scan Summary

**Module:** $module
**Total Targets:** $total
**Threads:** $threads
**Duration:** ${duration}s
**Speed:** $(echo "scale=2; $total / $duration" | bc) targets/sec

## Results

- ✅ Successful: $success
- ❌ Failed: $failed

## Results Directory

All logs saved to: $results_dir/
EOF
    
    print_success "Parallel scan complete! Results: $results_dir/"
}
PARALLELEOF

chmod +x core/parallel.sh
echo "   ✅ Parallel Scanning installed"

# ============================================================================
# UPDATE MAIN SCRIPT
# ============================================================================
echo ""
echo "🔧 Updating pilgrims.sh with new commands..."

# Add new commands to pilgrims.sh
cat >> pilgrims.sh << 'APPENDEOF'

# Load new core modules
source "$SCRIPT_DIR/core/resume.sh" 2>/dev/null
source "$SCRIPT_DIR/core/compare.sh" 2>/dev/null
source "$SCRIPT_DIR/core/attack_path.sh" 2>/dev/null
source "$SCRIPT_DIR/core/mitre.sh" 2>/dev/null
source "$SCRIPT_DIR/core/parallel.sh" 2>/dev/null

# Handle new commands in argument parser
for arg in "$@"; do
    case $arg in
        --resume=*)
            RESUME_DIR="${arg#*=}"
            resume_scan "$RESUME_DIR"
            exit 0
            ;;
        --resume-list)
            list_resumable_scans
            exit 0
            ;;
        --compare)
            if [ -n "$SCAN_TYPE" ] && [ -n "$TARGET" ]; then
                compare_scans "$SCAN_TYPE" "$TARGET"
            else
                echo "Usage: $0 --module=<type> <target> --compare"
            fi
            exit 0
            ;;
        --attack-paths)
            if [ -n "$OUTPUT_DIR" ]; then
                map_attack_paths "$OUTPUT_DIR"
            else
                echo "Run a scan first, then use --attack-paths"
            fi
            exit 0
            ;;
        --mitre)
            if [ -n "$OUTPUT_DIR" ]; then
                map_to_mitre "$OUTPUT_DIR"
            else
                echo "Run a scan first, then use --mitre"
            fi
            exit 0
            ;;
        --parallel=*)
            PARALLEL_FILE="${arg#*=}"
            if [ -n "$SCAN_TYPE" ]; then
                parallel_scan "$PARALLEL_FILE" "$SCAN_TYPE" 4
            else
                echo "Usage: $0 --module=<type> --parallel=targets.txt"
            fi
            exit 0
            ;;
    esac
done
APPENDEOF

echo "   ✅ Main script updated"

# ============================================================================
# UPDATE INTERACTIVE MENU
# ============================================================================
echo ""
echo "🎨 Updating interactive menu..."

# Add new options to interactive menu
sed -i '/\[ Q\].*Quit/i\    ━━━ ⚡ ADVANCED FEATURES ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n    [28] 🔄 Resume Previous Scan\n    [29] 📊 Compare Scans\n    [30] 🗺️  Attack Path Mapper\n    [31] 🎯 MITRE ATT&CK Mapping\n    [32] ⚡ Parallel Scanning\n' core/interactive_menu.sh

# Add handlers for new options
cat >> core/interactive_menu.sh << 'MENUAPPENDEOF'

# Add handlers in handle_menu_choice
handle_menu_choice() {
    local choice=$1
    case $choice in
        28) list_resumable_scans ;;
        29) 
            echo -ne "    Module: "; read -r m
            echo -ne "    Target: "; read -r t
            compare_scans "$m" "$t"
            ;;
        30)
            echo -ne "    Scan directory: "; read -r d
            map_attack_paths "$d"
            ;;
        31)
            echo -ne "    Scan directory: "; read -r d
            map_to_mitre "$d"
            ;;
        32)
            echo -ne "    Targets file: "; read -r f
            echo -ne "    Module: "; read -r m
            parallel_scan "$f" "$m" 4
            ;;
    esac
}
MENUAPPENDEOF

echo "   ✅ Interactive menu updated"

# ============================================================================
# FINAL SUMMARY
# ============================================================================
echo ""
echo "═══════════════════════════════════════════════════"
echo "✅ PILGRIMS v17.0 UPGRADE COMPLETE!"
echo ""
echo "📦 New Features Installed:"
echo "   🔄 Resume Scan System"
echo "   📊 Comparative Analysis"
echo "   🗺️  Attack Path Mapper"
echo "   🎯 MITRE ATT&CK Mapping"
echo "   ⚡ Parallel Scanning"
echo ""
echo "🧪 Test now:"
echo "   ./pilgrims.sh --help"
echo "   ./pilgrims.sh --resume-list"
echo "   ./pilgrims.sh --module=web example.com --quick"
echo "   ./pilgrims.sh --module=web example.com --compare"
echo "   ./pilgrims.sh --module=web example.com --attack-paths"
echo "   ./pilgrims.sh --module=web example.com --mitre"
echo ""
echo "═══════════════════════════════════════════════════"
