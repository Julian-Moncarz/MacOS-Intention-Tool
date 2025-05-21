FROM ubuntu:latest

# Install required dependencies
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    python3 \
    python3-pip \
    python3-venv \
    bash \
    vim \
    git

# Create a test user to simulate home directory
RUN useradd -m testuser
USER testuser
WORKDIR /home/testuser

# Set up environment to simulate macOS paths
RUN mkdir -p /home/testuser/Library/LaunchAgents

# Create a mock launchctl command to simulate macOS behavior
RUN echo '#!/bin/bash\necho "Simulated launchctl: $@"\n' > /home/testuser/launchctl && \
    chmod +x /home/testuser/launchctl

# Add the mock launchctl to PATH
ENV PATH="/home/testuser:${PATH}"

# Command to run when container starts
CMD ["/bin/bash"]
