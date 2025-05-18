#!/bin/bash

# Sifter App Performance Testing Script
# This script runs various performance tests on the Sifter app

# Terminal colors for better visibility
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create log directory
LOG_DIR="test-logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/test_run_$(date +%Y%m%d_%H%M%S).log"

# Helper functions
log() {
  local message=$1
  local level=${2:-INFO}
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo -e "[$timestamp] [$level] $message"
  echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

print_header() {
  local title=$1
  echo -e "\n${BLUE}======================================${NC}"
  echo -e "${BLUE}$title${NC}"
  echo -e "${BLUE}======================================${NC}\n"
  log "$title" "HEADER"
}

# Function to run a test with timing and error handling
run_test() {
  local test_name=$1
  local command=$2
  
  log "Running $test_name..." "TEST"
  log "Command: $command" "COMMAND"
  
  # Record start time
  start_time=$(date +%s)
  
  # Run the command and capture both stdout and stderr
  echo -e "${YELLOW}Running $test_name...${NC}"
  echo -e "Command: ${BLUE}$command${NC}\n"
  
  # Run command and capture exit status
  eval $command > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)
  exit_status=$?
  
  # Record end time
  end_time=$(date +%s)
  duration=$((end_time - start_time))
  
  if [ $exit_status -eq 0 ]; then
    echo -e "\n${GREEN}$test_name completed in $duration seconds${NC}"
  else
    echo -e "\n${RED}$test_name FAILED in $duration seconds (exit code: $exit_status)${NC}"
    log "$test_name FAILED with exit code: $exit_status" "ERROR"
  fi
  echo -e "${BLUE}----------------------------------------${NC}"
  log "Test duration: $duration seconds" "INFO"
}

# Validate comma-separated list input
validate_csv_input() {
  local input=$1
  local allowed_values=$2
  local input_array
  
  IFS=',' read -ra input_array <<< "$input"
  
  for item in "${input_array[@]}"; do
    item=$(echo "$item" | xargs) # Trim whitespace
    if ! echo "$allowed_values" | grep -q "$item"; then
      echo -e "${RED}Invalid value: '$item'. Allowed values: $allowed_values${NC}"
      return 1
    fi
  done
  
  return 0
}

# Function to get valid device list
get_valid_devices() {
  dart -e "import 'test/stress_test_config.dart'; void main() { print(StressTestConfig.deviceMatrix.map((d) => d['name']).join(',')); }" 2>/dev/null || echo "iPhone 15 Pro Max,Google Pixel 7 Pro,Samsung Galaxy S23 Ultra"
}

# Function to get valid scenario list
get_valid_scenarios() {
  dart -e "import 'test/stress_test_config.dart'; void main() { print(StressTestConfig.testScenarios.keys.join(',')); }" 2>/dev/null || echo "standard_user_flow,location_stress_test,memory_load_test,network_resilience_test"
}

# Start script
print_header "Sifter App Performance Testing Script"
log "Test run started" "INFO"

# Create directory for test results if it doesn't exist
mkdir -p test-results
log "Created test-results directory if it didn't exist" "INFO"

# Run the demo test
run_test "Demo Test" "dart test/run_test_demo.dart"

# Get valid device and scenario lists for validation
VALID_DEVICES=$(get_valid_devices)
VALID_SCENARIOS=$(get_valid_scenarios)

# Ask if user wants to run specific device tests
echo -e "\n${YELLOW}Would you like to run tests on specific devices? (y/n)${NC}"
read -r run_device_tests

if [[ $run_device_tests =~ ^[Yy]$ ]]; then
  echo -e "Available devices: ${BLUE}${VALID_DEVICES/,/, }${NC}"
  echo "Enter device names separated by commas (e.g., 'iPhone 15,Google Pixel 7 Pro'):"
  read -r device_list
  
  if [[ -n $device_list ]]; then
    if validate_csv_input "$device_list" "$VALID_DEVICES"; then
      run_test "Device-specific tests" "dart test/run_stress_tests.dart --devices=\"$device_list\""
    else
      log "Invalid device selection: $device_list" "ERROR"
    fi
  fi
fi

# Ask if user wants to run specific scenario tests
echo -e "\n${YELLOW}Would you like to run specific test scenarios? (y/n)${NC}"
read -r run_scenario_tests

if [[ $run_scenario_tests =~ ^[Yy]$ ]]; then
  echo -e "Available scenarios: ${BLUE}${VALID_SCENARIOS/,/, }${NC}"
  echo "Enter scenario names separated by commas (e.g., 'network_resilience_test,memory_load_test'):"
  read -r scenario_list
  
  if [[ -n $scenario_list ]]; then
    if validate_csv_input "$scenario_list" "$VALID_SCENARIOS"; then
      run_test "Scenario-specific tests" "dart test/run_stress_tests.dart --scenarios=\"$scenario_list\""
    else
      log "Invalid scenario selection: $scenario_list" "ERROR"
    fi
  fi
fi

# Ask if user wants to run integration tests
echo -e "\n${YELLOW}Would you like to run integration tests? (y/n)${NC}"
read -r run_integration_tests

if [[ $run_integration_tests =~ ^[Yy]$ ]]; then
  # Check if integration test file exists
  if [ -f "integration_test/app_test.dart" ]; then
    run_test "Integration Tests" "flutter test integration_test/app_test.dart"
  else
    echo -e "${RED}Error: integration_test/app_test.dart not found${NC}"
    log "Integration test file not found: integration_test/app_test.dart" "ERROR"
  fi
fi

# Run full tests if requested
echo -e "\n${YELLOW}Would you like to run the full test suite? This will take some time. (y/n)${NC}"
read -r run_full_tests

if [[ $run_full_tests =~ ^[Yy]$ ]]; then
  run_test "Full Stress Test Suite" "dart test/run_stress_tests.dart"
fi

print_header "Testing completed!"
echo -e "${GREEN}Test results are available in the test-results directory${NC}"
echo -e "${BLUE}Test logs are available in: $LOG_FILE${NC}" 

log "Test run completed" "INFO" 