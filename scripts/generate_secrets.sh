#!/bin/bash

# Exit on error
set -e

# Generate random passwords
generate_password() {
  openssl rand -base64 12 | tr -dc '0-9' | head -c 8
}

# Create .env file
cat > .env << EOF
# GCP Configuration
GCP_PROJECT_ID=eq-infrasupp-test-02
GCP_REGION=us-central1
GCP_ZONE=us-central1-a

# FreeIPA Configuration
IPA_DOMAIN=ipa.sindoatan.ru
IPA_SHORT=ipa
IPA_REALM=IPA.SINDOATAN.RU
IPA_ADMIN_PASSWORD=$(generate_password)
IPA_DS_PASSWORD=$(generate_password)

# User Passwords
USER1_PASSWORD=$(generate_password)
USER2_PASSWORD=$(generate_password)
USER3_PASSWORD=$(generate_password)
REVIEWER_PASSWORD=$(generate_password)
EOF

# Set proper permissions
chmod 600 .env

echo "Secrets generated and saved to .env file"
echo "Please update GCP_PROJECT_ID with your actual project ID" 