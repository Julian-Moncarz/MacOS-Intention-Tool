#!/bin/bash

# Script to run all Intention Tool tests in sequence

echo "=== Running All Intention Tool Tests ==="
echo ""

# Create and activate a Python virtual environment for testing
echo "Setting up Python virtual environment for testing..."
python3 -m venv venv_test
source venv_test/bin/activate

# Function to run a test and report its status
run_test() {
    local test_script=$1
    local test_name=$2
    
    echo "Running $test_name..."
    echo "======================================"
    
    if ./$test_script; then
        echo "✅ $test_name PASSED"
        return 0
    else
        echo "❌ $test_name FAILED"
        return 1
    fi
    
    echo ""
}

# Run the Launch Agent Configuration Test
run_test "test_launch_agent.sh" "Launch Agent Configuration Test"
echo ""

# Run the One-Line Setup Test
run_test "test_one_line_setup.sh" "One-Line Setup Test"
echo ""

# Run the One-Line Command Test
run_test "test_one_line_command.sh" "One-Line Command Test"
echo ""

# All tests completed

# Deactivate the virtual environment
deactivate
rm -rf venv_test

echo "=== All Tests Completed ==="
