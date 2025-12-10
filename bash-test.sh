#!/bin/sh

# Interactive POSIX Log Auditor - works on dash, BusyBox, ash, ksh, etc.

# Simple colors (will be ignored if terminal doesn't support them)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Human-readable size using only POSIX tools
human_size() {
    sz=$1
    if [ "$sz" -lt 1024 ]; then
        printf '%dB' "$sz"
    elif [ "$sz" -lt 1048576 ]; then
        printf '%dK' "$((sz / 1024))"
    elif [ "$sz" -lt 1073741824 ]; then
        printf '%dM' "$((sz / 1048576))"
    else
        printf '%dG' "$((sz / 1073741824))"
    fi
}

clear
printf '%bSystem Log Auditor%b\n\n' "$GREEN" "$NC"

# Basic access check
if ! [ -d /var/log ] || ! [ -r /var/log ]; then
    printf '%bError: Cannot read /var/log (permission denied or missing)%b\n' "$RED" "$NC"
    exit 1
fi

# Main loop
while true; do
    clear
    printf '%b=== Log Audit Menu ===%b\n\n' "$YELLOW" "$NC"
    printf '1) Show 5 largest files in /var/log\n'
    printf '2) Count lines containing "error" (case-insensitive)\n'
    printf '3) List .log files not modified in the last 7 days\n'
    printf '4) Check if total log size exceeds 1 GB\n'
    printf '5) Quit\n\n'
    printf 'Choose [1-5]: '
    read choice
    printf '\n'

    case "$choice" in
        1)
            printf '%bFive Largest Files in /var/log%b\n' "$YELLOW" "$NC"
            printf '%-10s %s\n' "SIZE" "PATH"
            printf '%-10s %s\n' "--------" "----"
            find /var/log -type f 2>/dev/null -exec ls -s {} + 2>/dev/null | \
                sort -nr | head -5 | while read size path; do
                    [ "$size" = "0" ] && continue
                    hsize=$(human_size $((size * 1024)))
                    printf '%-10s %s\n' "$hsize" "$path"
                done
            printf '\n'
            ;;

        2)
            printf '%bCounting "error" lines in *.log files...%b\n' "$YELLOW" "$NC"
            total=$(find /var/log -type f -name '*.log' 2>/dev/null -exec grep -i -c 'error' {} + 2>/dev/null | \
                    awk '{s+=$1} END {print s+0}')
            printf 'Total lines containing "error" (case-insensitive): %b%s%b\n\n' "$GREEN" "${total:-0}" "$NC"
            ;;

        3)
            printf '%b.log Files Not Modified in the Last 7 Days%b\n' "$YELLOW" "$NC"
            found=0
            find /var/log -type f -name '*.log' -mtime +6 2>/dev/null | sort | \
            while read file; do
                [ "$found" -eq 0 ] && printf '%-12s %s\n%-12s %s\n' "AGE" "PATH" "----" "----"
                found=1
                # Approximate days old
                if stat -c %Y "$file" >/dev/null 2>&1 2>/dev/null; then
                    mtime=$(stat -c %Y "$file")
                else
                    mtime=$(stat -f %m "$file" 2>/dev/null || echo 0)
                fi
                now=$(date +%s 2>/dev/null || echo 0)
                days=$(((now - mtime) / 86400))
                printf '%-12s %s\n' "${days}d" "$file"
            done
            [ "$found" -eq 0 ] && printf 'None found.\n'
            printf '\n'
            ;;

        4)
            printf '%bTotal /var/log Size Check%b\n' "$YELLOW" "$NC"
            total_kb=$(du -sk /var/log 2>/dev/null | cut -f1)
            total_kb=${total_kb:-0}
            total_human=$(human_size $((total_kb * 1024)))
            printf 'Total size: %s\n' "$total_human"

            if [ "$total_kb" -gt 1048576 ]; then
                printf '%bWarning: /var/log exceeds 1 GB!%b\n' "$RED" "$NC"
                printf 'Top 3 contributors:\n'
                printf '%-10s %s\n' "SIZE" "PATH"
                printf '%-10s %s\n' "--------" "----"
                find /var/log -type f 2>/dev/null -exec ls -s {} + 2>/dev/null | \
                    sort -nr | head -3 | while read size path; do
                        [ "$size" = "0" ] && continue
                        hsize=$(human_size $((size * 1024)))
                        printf '%-10s %s\n' "$hsize" "$path"
                    done
            else
                printf '%bWithin limits (< 1 GB)%b\n' "$GREEN" "$NC"
            fi
            printf '\n'
            ;;

        5|q|Q)
            printf 'Goodbye!\n'
            exit 0
            ;;

        *)
            printf '%bInvalid choice%b\n\n' "$RED" "$NC"
            ;;
    esac

    printf 'Press Enter to return to menu...'
    read dummy
done
