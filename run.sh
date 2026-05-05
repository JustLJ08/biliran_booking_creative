#!/bin/bash

# Function to clean up background processes on exit
cleanup() {
    echo "Stopping backend server..."
    if [ -n "$BACKEND_PID" ]; then
        kill $BACKEND_PID 2>/dev/null
    fi
}

# Set up the trap to catch termination signals
trap cleanup SIGINT SIGTERM EXIT

echo "Starting Django backend..."
# Navigate to backend, activate virtual environment, and run server
cd backend
if [ -d "venv" ]; then
    source venv/bin/activate
fi
python manage.py runserver &
BACKEND_PID=$!
cd ..

echo "Backend started with PID $BACKEND_PID"

# Wait a brief moment for the backend to initialize
sleep 2

echo "Starting Flutter frontend..."
# Run the Flutter app in the foreground so you can still use hot-reload (r, R, etc.)
flutter run
