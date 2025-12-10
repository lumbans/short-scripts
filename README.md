Bash script that audits the current system:
1. Find the five largest files under /var/log and print their sizes (human-readable).
2. Count total lines that contain error (case-insensitive) across all .log files.
3. Detect if any .log file hasn’t been modified in the last 7 days and list them.
4. If total log size exceeds 1 GB, print a warning and show the top 3 contributors.
