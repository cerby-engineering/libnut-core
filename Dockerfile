# Dockerfile for building and testing libnut-core on Linux
FROM node:24-bullseye

# Install system dependencies required for building and running libnut
RUN apt-get update && apt-get install -y \
    # Build essentials
    build-essential \
    ninja-build \
    python3 \
    python3-pip \
    # X11 development libraries (required for libnut Linux functionality)
    libx11-dev \
    libxtst-dev \
    libxrandr-dev \
    libxinerama-dev \
    libxcursor-dev \
    libxdamage-dev \
    libxfixes-dev \
    libxcomposite-dev \
    # X11 runtime libraries
    xvfb \
    x11-utils \
    x11-xserver-utils \
    # Cleanup
    && rm -rf /var/lib/apt/lists/*

# Install newer CMake (3.20+ required) via pip
RUN pip3 install cmake>=3.20 \
    && cmake --version

# Set up a virtual display for headless testing
ENV DISPLAY=:99
ENV XVFB_WHD=1920x1080x24

# Create working directory
WORKDIR /app

# Copy package files first to leverage Docker layer caching
COPY package*.json ./

# Install Node.js dependencies
RUN npm install

# Copy the rest of the source code
COPY . .

# Create a script to start virtual display and run commands
RUN echo '#!/bin/bash\n\
# Start virtual display\n\
Xvfb :99 -screen 0 $XVFB_WHD -ac +extension GLX +render -noreset &\n\
XVFB_PID=$!\n\
\n\
# Wait for X server to start\n\
sleep 2\n\
\n\
# Execute the command passed as arguments\n\
exec "$@"\n\
' > /usr/local/bin/xvfb-run-custom && chmod +x /usr/local/bin/xvfb-run-custom

# Build the native addon
RUN npm run build:release

# Default command: run tests
CMD ["xvfb-run-custom", "sh", "-c", "cd test && npm install && npm test"]

# Build instructions:
# docker build -t libnut-linux .
#
# Run tests:
# docker run --rm libnut-linux
#
# Interactive shell for debugging:
# docker run --rm -it libnut-linux bash
#
# Build only (without tests):
# docker run --rm libnut-linux npm run build:release
#
# Run specific test:
# docker run --rm libnut-linux xvfb-run-custom sh -c "cd test && npm install && node bitmap.js"
