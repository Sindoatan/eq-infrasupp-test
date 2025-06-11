# Infrastructure Support Test Environment

This repository contains the infrastructure code and automation scripts for setting up a test environment with an LDAP server and an application server.

## Prerequisites

- Google Cloud Platform account
- Google Cloud SDK installed
- Terraform installed
- Ansible installed
- Git installed

## Environment Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/Sindoatan/eq-infrasupp-test.git
   cd eq-infrasupp-test
   ```

2. Generate secrets:
   ```bash
   ./scripts/generate_secrets.sh
   ```

3. Update the `.env` file with your GCP project ID:
   ```bash
   sed -i 's/your-project-id/YOUR_ACTUAL_PROJECT_ID/' .env
   ```

4. Source the environment variables:
   ```bash
   source .env
   ```

5. Create the environment:
   ```bash
   ./scripts/env_create.sh
   ```

## Testing the Environment

Run the test script to verify the setup:
```bash
./scripts/env_test.sh
```

## Environment Cleanup

To destroy the environment:
```bash
./scripts/env_clear.sh
```

## Environment Details

### LDAP Server (FreeIPA)
- Rocky Linux 9
- FreeIPA server installed and configured
- Users created:
  - user1: SSH access + read permission on Docker directory
  - user2: SSH access + write permission on Docker directory
  - user3: SSH access + read/write permissions on Docker directory
  - reviewer: Full access for testing

### Application Server
- Ubuntu 22.04 LTS
- LVM configured with /app partition
- Docker installed and configured to use /app directory
- SSSD configured for LDAP authentication

## Access Information

After environment creation, the script will output the IP addresses for both servers. Use these IPs to access the servers:

```bash
# LDAP Server
ssh reviewer@<LDAP_SERVER_IP>

# Application Server
ssh reviewer@<APP_SERVER_IP>
```

## Security Notes

- All sensitive data is stored in the `.env` file
- SSH keys are generated and stored securely
- Firewall rules are limited to necessary ports
- Regular security updates are enabled
- Access logging is enabled

## Cost Optimization

- Using e2-micro instances (free tier eligible)
- Minimal disk sizes
- Single region deployment
- Automatic shutdown during non-working hours