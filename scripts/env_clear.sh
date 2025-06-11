#!/bin/bash

# Exit on error
set -e

# Clear Ansible facts cache
cd ../ansible
if [ -d facts/ ]; then
    echo "Clearing Ansible facts cache..."
    sudo rm -rf facts/*
else
    echo "No Ansible facts cache directory found."
fi

# Destroy Terraform resources
cd ../terraform
terraform destroy -auto-approve

# Clean up local files
rm -f ~/.ssh/reviewer*
rm -f ~/.ssh/test_lab_key*

echo "Environment cleanup completed successfully!" 