#!/bin/bash
# start_orion_usb.sh
# ---------------------------------------------------------
# ORION Portable Pen-Drive Launcher
# Enables completely stateless execution off a USB drive.
# All cache, databases, and logs remain in the current folder.
# ---------------------------------------------------------

echo "[ORION] Initializing USB Live / Portable Mode..."

# Resolve absolute path to the directory where this script sits (e.g. the USB mount point)
USB_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
cd "$USB_DIR"

echo "Current execution path locked to: $USB_DIR"

# Force HF caching and NeMo caching to point to the local USB directory
# This prevents ORION from downloading gigabytes into the host machine's ~/.cache
export HF_HOME="$USB_DIR/models/.cache/huggingface"
export NEMO_CACHE_DIR="$USB_DIR/models/.cache/nemo"
export ORION_RAG_DIR="$USB_DIR/storage/docs"

echo "Configured environment variables to prevent host OS contamination."

# Ensure sub-directories exist
mkdir -p "$HF_HOME"
mkdir -p "$NEMO_CACHE_DIR"
mkdir -p "$ORION_RAG_DIR"

echo "[ORION] Launching cognitive core in the foreground for USB session..."

# 1. Activate Local USB Environment
if [ -d "$USB_DIR/env/ORION-env" ]; then
    echo "Activating portable virtual environment..."
    source "$USB_DIR/env/ORION-env/bin/activate"
else
    echo "⚠️ Warning: No ORION-env found. Attempting to run with system python."
fi

# 2. Start Backend & Frontend concurrently in the same terminal
pkill -f "python3 server.py"
pkill -f "npm run dev"
pkill -f vite

echo "Starting Backend..."
cd "$USB_DIR/core"
python3 server.py > ../logs/orion_backend.log 2>&1 &
BACKEND_PID=$!

sleep 5

echo "Starting Frontend..."
cd "$USB_DIR/orion_ui"
npm run dev > ../logs/orion_frontend.log 2>&1 &
FRONTEND_PID=$!

cd "$USB_DIR"
echo "======================================================"
echo "🔌 ORION IS ONLINE (USB Portable Mode)"
echo "Backend PID: $BACKEND_PID"
echo "Frontend PID: $FRONTEND_PID"
echo "Interface available at: http://localhost:5173"
echo "Press [CTRL+C] to shutdown ORION and safely remove USB."
echo "======================================================"

# Wait for trap to gracefully shutdown
trap "echo '[ORION] Shutting down...'; kill $BACKEND_PID $FRONTEND_PID 2>/dev/null; exit 0" SIGINT SIGKILL SIGTERM

wait
