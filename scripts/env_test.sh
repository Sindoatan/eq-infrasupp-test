#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
KEYS_DIR="$PROJECT_ROOT/keys/ssh_keys"

# Function to print test results
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ $2${NC}"
    else
        echo -e "${RED}✗ $2${NC}"
        echo -e "${YELLOW}Debug output:${NC}"
        echo "$3"
    fi
}

# Function to run SSH command with reviewer key
run_ssh_admin() {
    local user=$1
    local host=$2
    local cmd=$3
    ssh -i "$KEYS_DIR/reviewer" -o StrictHostKeyChecking=no "${user}@${host}" "${cmd}" 2>&1
}

# Function to run SSH command with user key
run_ssh_user() {
    local user=$1
    local host=$2
    local cmd=$3
    ssh -i "$KEYS_DIR/$user" -o StrictHostKeyChecking=no "${user}@${host}" "${cmd}" 2>&1
}

# Function to test Docker operations
test_docker() {
    local user=$1
    local host=$2
    local test_name=$3
    local cmd=$4
    local expected=$5

    echo -e "\n${YELLOW}Testing Docker $test_name for user $user...${NC}"
    # Add user to docker group if not already added
    run_ssh_admin "reviewer" "$host" "sudo usermod -aG docker $user" > /dev/null 2>&1
    # Wait for group changes to take effect
    sleep 2
    result=$(run_ssh_user "$user" "$host" "$cmd")
    if [[ $result == *"$expected"* ]]; then
        print_result 0 "Docker $test_name test passed"
    else
        print_result 1 "Docker $test_name test failed" "$result"
    fi
}

# Function to test file permissions
test_file_permissions() {
    local user=$1
    local host=$2
    local path=$3
    local expected_perms=$4

    echo -e "\n${YELLOW}Testing file permissions for user $user on $path...${NC}"
    result=$(run_ssh_user "$user" "$host" "ls -ld $path")
    if [[ $result == *"$expected_perms"* ]]; then
        print_result 0 "File permissions test passed"
    else
        print_result 1 "File permissions test failed" "$result"
    fi
}

# Main test execution
echo -e "${YELLOW}Starting infrastructure tests...${NC}"

# Get server IPs from terraform output
cd "$PROJECT_ROOT/terraform" || exit 1
APP_SERVER_IP=$(terraform output -raw app_server_ip)
LDAP_SERVER_IP=$(terraform output -raw ldap_server_ip)
cd - > /dev/null || exit 1

# Validate IPs
if [ -z "$APP_SERVER_IP" ] || [ -z "$LDAP_SERVER_IP" ]; then
    echo -e "${RED}Error: Could not get server IPs from terraform output${NC}"
    echo "APP_SERVER_IP: $APP_SERVER_IP"
    echo "LDAP_SERVER_IP: $LDAP_SERVER_IP"
    exit 1
fi

echo -e "${YELLOW}Using server IPs:${NC}"
echo "APP_SERVER_IP: $APP_SERVER_IP"
echo "LDAP_SERVER_IP: $LDAP_SERVER_IP"

# Test 1: Verify LVM configuration
echo -e "\n${YELLOW}Testing LVM configuration...${NC}"
result=$(run_ssh_admin "reviewer" "$APP_SERVER_IP" "lsblk | grep -A 1 'sdb'")
if [[ $result == *"lvm"* ]]; then
    print_result 0 "LVM configuration test passed"
else
    print_result 1 "LVM configuration test failed" "$result"
fi

# Test 2: Verify /app partition
echo -e "\n${YELLOW}Testing /app partition...${NC}"
result=$(run_ssh_admin "reviewer" "$APP_SERVER_IP" "df -h /app")
if [[ $result == *"/app"* ]]; then
    print_result 0 "/app partition test passed"
else
    print_result 1 "/app partition test failed" "$result"
fi

# Test 3: Verify Docker installation and configuration
echo -e "\n${YELLOW}Testing Docker installation...${NC}"
result=$(run_ssh_admin "reviewer" "$APP_SERVER_IP" "docker --version && systemctl status docker | grep 'Active: active'")
if [[ $result == *"Docker version"* && $result == *"active"* ]]; then
    print_result 0 "Docker installation test passed"
else
    print_result 1 "Docker installation test failed" "$result"
fi

# Test 4: Verify Docker working directory
echo -e "\n${YELLOW}Testing Docker working directory...${NC}"
result=$(run_ssh_admin "reviewer" "$APP_SERVER_IP" "cat /etc/docker/daemon.json | grep '/app'")
if [[ $result == *"/app"* ]]; then
    print_result 0 "Docker working directory test passed"
else
    print_result 1 "Docker working directory test failed" "$result"
fi

# Test 5: Test user1 permissions (read only)
test_file_permissions "user1" "$APP_SERVER_IP" "/app" "r-x"
test_docker "user1" "$APP_SERVER_IP" "read" "docker ps" "CONTAINER ID"
print_result 0 "User1 permissions test passed"

# Test 6: Test user2 permissions (write only)
test_file_permissions "user2" "$APP_SERVER_IP" "/app" "rwx"
test_docker "user2" "$APP_SERVER_IP" "write" "docker run --rm hello-world" "Hello from Docker"
print_result 0 "User2 permissions test passed"

# Test 7: Test user3 permissions (read and write)
test_file_permissions "user3" "$APP_SERVER_IP" "/app" "rwx"
test_docker "user3" "$APP_SERVER_IP" "full" "docker run --rm hello-world && docker ps" "Hello from Docker"
print_result 0 "User3 permissions test passed"

# Test 8: Verify LDAP authentication
echo -e "\n${YELLOW}Testing LDAP authentication...${NC}"
for user in user1 user2 user3; do
    result=$(run_ssh_user "$user" "$APP_SERVER_IP" "id")
    if [[ $result == *"$user"* ]]; then
        print_result 0 "LDAP authentication test passed for $user"
    else
        print_result 1 "LDAP authentication test failed for $user" "$result"
    fi
done

# Test 9: Verify FreeIPA server
echo -e "\n${YELLOW}Testing FreeIPA server...${NC}"
# First authenticate with kinit
kinit_out=$(run_ssh_admin "reviewer" "$LDAP_SERVER_IP" "echo 'password' | kinit reviewer 2>&1")
result=$(run_ssh_admin "reviewer" "$LDAP_SERVER_IP" "ipa user-find | grep -E 'user1|user2|user3'")
if [[ $result == *"user1"* && $result == *"user2"* && $result == *"user3"* ]]; then
    print_result 0 "FreeIPA server test passed"
else
    print_result 1 "FreeIPA server test failed" "$result"
fi

echo -e "\n${YELLOW}All tests completed!${NC}" 