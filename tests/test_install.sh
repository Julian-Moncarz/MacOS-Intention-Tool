#!/bin/bash

# Test script for the Intention Tool one-line setup
# This script will build a Docker container and test the installation

echo "=== Intention Tool Installation Test ==="
echo "Building Docker container for testing..."

# Copy the current project files to a test directory in the container
mkdir -p test_files
cp -r ../focus_session.sh ../logs.csv ../requirements.txt ../install.sh ../visualize_logs.py ../README.md test_files/

# Update the Dockerfile to copy our test files
cat >> Dockerfile << EOL
# Copy project files for testing
COPY --chown=testuser:testuser test_files /home/testuser/test_repo
EOL

# Build the Docker image
docker build -t intention-tool-test .

# Run the container with an interactive shell
echo "Starting test container..."
echo "Once inside the container, you can test the one-line setup with:"
echo "bash -c \"curl -L https://raw.githubusercontent.com/Julian-Moncarz/MacOS-Intention-Tool/main/install.sh | bash\""
echo "Or test the local install.sh with:"
echo "bash /home/testuser/test_repo/install.sh"
echo ""
echo "When done testing, type 'exit' to leave the container and return to your host system."

docker run --rm -it intention-tool-test

# Clean up test files
rm -rf test_files

echo "Test container has been removed. All temporary files cleaned up."
