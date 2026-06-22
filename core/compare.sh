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
