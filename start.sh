#!/bin/sh
set -e

FIFO=/tmp/server-input

echo ">>> Starting Minecraft entrypoint..."

# Ensure scripts exist / are executable (optional - use in Dockerfile too)
chmod +x ./scripts/*.sh || true

# Pre-run tasks
./scripts/update_world.sh
./scripts/download_core_artifact.sh
./scripts/download_chat_artifact.sh

# Bluemap handling (same as yours)
BLUEMAP_PLUGIN="./plugins/bluemap-5.7-paper.jar"
BLUEMAP_OLD="./plugins/bluemap-5.7-paper.old"
if [ "$IS_LIVE_SERVER" = "true" ] && [ -f "$BLUEMAP_PLUGIN" ]; then
    echo ">>> Disabling Bluemap plugin for live server..."
    mv "$BLUEMAP_PLUGIN" "$BLUEMAP_OLD"
fi

# Create FIFO if missing
if [ ! -p "$FIFO" ]; then
    mkfifo "$FIFO"
fi

# Keep the write end open so the fifo doesn't block the java reader on start.
# tail -f /dev/null produces no output but keeps a writer open.
tail -f /dev/null > "$FIFO" &
FIFO_KEEPER=$!

# Start server reading from FIFO (so server stdin == contents of FIFO)
# NOTE: java reads from FIFO; server inherits the FIFO as stdin.
java -Xmx${JVM_XMX} -Xms${JVM_XMS} -jar ./server.jar nogui < "$FIFO" &
SERVER_PID=$!

# Graceful shutdown: write the command into the FIFO so the server receives it on stdin.
graceful_shutdown() {
    echo ">>> SIGTERM received, sending shutdown command to server stdin..."
    # ensure newline; use printf to avoid extra spaces
    printf 'admin restart 15 Template updated.\n' > "$FIFO" || true
    # wait for java to exit (respects stop_grace_period)
    wait "$SERVER_PID" || true
    echo ">>> Minecraft server stopped."
}

trap graceful_shutdown SIGTERM

# Wait for the server to exit (or for SIGTERM to trigger)
wait "$SERVER_PID"

# Cleanup FIFO keeper
kill "$FIFO_KEEPER" 2>/dev/null || true
rm -f "$FIFO"
