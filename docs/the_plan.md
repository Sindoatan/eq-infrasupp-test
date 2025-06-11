# Infrastructure Support Test Task Implementation Plan

## Overview
This document outlines the step-by-step implementation plan for setting up a test lab environment according to the requirements in `the_task.md`. The environment will consist of two servers:
1. LDAP Server (FreeIPA) on Rocky Linux
2. Application Server with Docker on Ubuntu 22.04

## Prerequisites
- Google Cloud Platform account with billing enabled
- Google Cloud SDK installed
- Terraform installed
- Ansible installed
- Git installed

## Implementation Steps

### 1. Project Setup and Initialization
**Task: Project Structure Creation**
- Create project directory structure
- Initialize Git repository
- Set up Terraform configuration
- Create Ansible playbooks structure

**Files to Create:**
```
.
├── .gitignore
├── LICENSE
├── README.md
├── ansible/
│   ├── group_vars/
│   │   ├── app.yml
│   │   └── ldap.yml
│   ├── inventory/
│   │   └── hosts.yml
│   ├── playbooks/
│   │   ├── app_setup.yml
│   │   └── ldap_setup.yml
│   │   └── templates/
│   │       ├── daemon.json.j2
│   │       └── sssd.conf.j2
├── docs/
│   ├── the_plan_10.md
│   └── the_task.md
├── scripts/
│   ├── env_clear.sh
│   ├── env_create.sh
│   ├── env_test.sh
│   └── generate_secrets.sh
└── terraform/
    ├── main.tf
    ├── outputs.tf
    ├── providers.tf
    └── variables.tf
```

### 2. Infrastructure as Code (Terraform)
**Task: GCP Resource Creation**
- Create VPC network
- Create firewall rules
- Create two VM instances:
  - LDAP server (Rocky Linux)
  - Application server (Ubuntu 22.04)
- Configure service accounts and IAM
- Set up Cloud Storage for state management

**Resource Specifications:**
- LDAP Server:
  - Machine type: e2-medium (2x.25 vCPU, 1 GB memory)  //e2-standard-8
  - Boot disk: 20 GB
  - Additional disk: 10 GB
- Application Server:
  - Machine type: e2-medium (2x.25 vCPU, 1 GB memory)  //e2-standard-8
  - Boot disk: 20 GB
  - Additional disk: 20 GB (for LVM)

### 3. LDAP Server Setup (FreeIPA)
**Task: LDAP Server Configuration**
- Install FreeIPA server
- Configure FreeIPA server
- Create user accounts:
  - user1 (SSH + read)
  - user2 (SSH + write)
  - user3 (SSH + read/write)
- Configure SSH access
- Set up reviewer account

### 4. Application Server Setup
**Task: Application Server Configuration**
- Configure LVM
- Create /app partition
- Install Docker
- Configure Docker to use /app directory
- Enable Docker service
- Configure user permissions

### 5. Security and Access Configuration
**Task: Security Setup**
- Generate and secure SSH keys
- Configure firewall rules
- Set up user permissions
- Secure sensitive data storage

### 6. Testing and Validation
**Task: Environment Testing**
- Test LDAP authentication
- Verify user permissions
- Test Docker functionality
- Validate LVM configuration
- Test SSH access for all users

### 7. Documentation and Cleanup
**Task: Documentation and Cleanup**
- Document setup process
- Create cleanup scripts
- Document test results
- Create user access instructions

