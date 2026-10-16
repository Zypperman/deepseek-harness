#!/bin/bash

# ==========================================
# CONFIGURATION
# ==========================================

# 1. The command you use to start your frontend/harness locally
START_CMD="npm run build" # Change to 'npm run dev' or your specific start command

# 2. The exact console text that indicates plugins are fully loaded.
# (e.g., "ready in", "Server listening", or a custom log from your proxy)
READY_MSG="plugins loaded" # <--- YOU MUST UPDATE THIS TO MATCH YOUR LOGS

LOG_DIR="aa-logs"
TRACE_LOG="$LOG_DIR/dsh_trace.log"
APP_LOG="$LOG_DIR/app_output.log"

# ==========================================
# EXECUTION
# ==========================================

mkdir -p "$LOG_DIR"
> "$APP_LOG" # Clear out any previous logs

echo "🚀 Starting application and file trace..."
echo "👀 Watching console output for: '$READY_MSG'"
echo "------------------------------------------------"

# Run strace in the background.
# Console logs go to APP_LOG. System file traces go to TRACE_LOG.
strace -f -e trace=file -o "$TRACE_LOG" $START_CMD > "$APP_LOG" 2>&1 &
STRACE_PID=$!

# Tail the console log live, and loop through it line-by-line
tail -f "$APP_LOG" | while read -r line; do
    echo "$line" # Print the app's output to your terminal so you can watch it

    # If the line contains our target completion message
    if [[ "$line" == *"$READY_MSG"* ]]; then
        echo ""
        echo "🛑 '$READY_MSG' detected!"
        echo "🔪 Terminating Node.js and strace..."

        # Kill the child Node processes spawned by strace, then kill strace itself
        pkill -P $STRACE_PID
        kill $STRACE_PID 2>/dev/null

        echo "✅ Trace cleanly stopped."
        echo "📂 File interactions saved to: $TRACE_LOG"

        # Kill the tail process to exit the script gracefully
        pkill -P $$ tail
        exit 0
    fi
done