# Intention Tool Tests

This directory contains test scripts for validating the Intention Tool installation process and Launch Agent configuration.

## Available Tests

### 1. Launch Agent Configuration Test (`test_launch_agent.sh`)

This test validates that the Launch Agent configuration in the installation script is correctly formatted and contains the expected settings.

**What it tests:**
- Validates the plist file format
- Checks for required keys in the plist file
- Verifies that KeepAlive is set to false (prevents multiple instances)
- Verifies that RunAtLoad is set to true (runs at system startup)
- Confirms that the program arguments point to the correct script

**How to run:**
```bash
./test_launch_agent.sh
```

### 2. One-Line Setup Test (`test_one_line_setup.sh`)

This test simulates the installation process in a temporary directory structure to verify that the installation script works correctly.

**What it tests:**
- Creates a temporary directory structure
- Copies the required files
- Sets up a Python virtual environment
- Makes the focus_session.sh script executable
- Creates the Launch Agent plist file
- Validates the plist file configuration

**How to run:**
```bash
./test_one_line_setup.sh
```

### 3. One-Line Command Test (`test_one_line_command.sh`)

This test simulates the actual one-line setup command that users would run, using a local HTTP server to serve the installation script.

**What it tests:**
- Simulates the `curl | bash` one-line installation command
- Creates a temporary HOME directory for testing
- Modifies the install script to use the test HOME directory
- Verifies the complete installation process
- Validates the Launch Agent configuration

**How to run:**
```bash
./test_one_line_command.sh
```



## Running All Tests

To run all tests in sequence, you can use the following command:

```bash
for test in test_launch_agent.sh test_one_line_setup.sh test_one_line_command.sh; do
  echo "Running $test..."
  ./$test
  echo ""
done
```

## Test Environment

All tests are designed to run in a temporary environment and clean up after themselves. They don't modify your actual system configuration or installation.
