#!/bin/bash

# Exit on error
set -e

# Source environment variables
if [ -f .env ]; then
    source .env
else
    echo "Error: .env file not found"
    exit 1
fi

# Check for required environment variables
required_vars=(
  "GCP_PROJECT_ID"
  "GCP_REGION"
  "GCP_ZONE"
  "IPA_DOMAIN"
  "IPA_SHORT"
  "IPA_REALM"
  "IPA_ADMIN_PASSWORD"
  "IPA_DS_PASSWORD"
  "USER1_PASSWORD"
  "USER2_PASSWORD"
  "USER3_PASSWORD"
  "REVIEWER_PASSWORD"
)

for var in "${required_vars[@]}"; do
  if [ -z "${!var}" ]; then
    echo "Error: $var is not set"
    exit 1
  fi
done

# Create new GCP project if it doesn't exist
if ! gcloud projects describe "$GCP_PROJECT_ID" >/dev/null 2>&1; then
  echo "Creating new GCP project: $GCP_PROJECT_ID"
  gcloud projects create "$GCP_PROJECT_ID" --name="Infrastructure Support Test"
  
  # Set as current project
  gcloud config set project "$GCP_PROJECT_ID"
  
  # Enable billing (requires manual intervention)
  echo "Please enable billing for the project in the GCP Console:"
  echo "https://console.cloud.google.com/billing/projects"
  read -p "Press Enter after enabling billing..."
  
  # Enable required APIs
  echo "Enabling required APIs..."
  gcloud services enable \
    compute.googleapis.com \
    cloudresourcemanager.googleapis.com \
    iam.googleapis.com \
    serviceusage.googleapis.com \
    cloudbuild.googleapis.com \
    artifactregistry.googleapis.com \
    storage.googleapis.com
fi

# Check if the service account key file exists
if [ ! -f "$(pwd)/service-account.json" ]; then
  echo "Setting up service account..."
  SA_NAME="terraform-sa"
  SA_EMAIL="${SA_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com"

  # Create service account if it doesn't exist
  if ! gcloud iam service-accounts describe "$SA_EMAIL" >/dev/null 2>&1; then
    gcloud iam service-accounts create "$SA_NAME" \
      --display-name="Terraform Service Account"
    
    # Grant necessary roles
    gcloud projects add-iam-policy-binding "$GCP_PROJECT_ID" \
      --member="serviceAccount:$SA_EMAIL" \
      --role="roles/editor"
    
    # Create and download key
    gcloud iam service-accounts keys create service-account.json \
      --iam-account="$SA_EMAIL"
    
    # Set the GOOGLE_APPLICATION_CREDENTIALS environment variable
    export GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/service-account.json"
  else
    echo "Service account $SA_EMAIL already exists."
  fi
else
  echo "Service account key already exists at scripts/service-account.json."
  export GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/service-account.json"
fi

# Create GCS bucket for Terraform state if it doesn't exist
BUCKET_NAME="${GCP_PROJECT_ID}-terraform-state"
if ! gsutil ls "gs://${BUCKET_NAME}" >/dev/null 2>&1; then
  echo "Creating GCS bucket for Terraform state..."
  gsutil mb -l "${GCP_REGION}" "gs://${BUCKET_NAME}"

  # Enable versioning for state file history
  gsutil versioning set on "gs://${BUCKET_NAME}"
  
  # Set lifecycle policy to delete old versions after 30 days
  cat > lifecycle.json << EOF
{
  "rule": [
    {
      "action": {"type": "Delete"},
      "condition": {
        "numNewerVersions": 5,
        "isLive": false
      }
    }
  ]
}
EOF
  gsutil lifecycle set lifecycle.json "gs://${BUCKET_NAME}"
  rm lifecycle.json
fi

# Create a terraform.tfvars file to pass the bucket name
cat > ../terraform/terraform.tfvars <<EOF
bucket_name = "${BUCKET_NAME}"
project_id = "${GCP_PROJECT_ID}"
EOF

# Generate SSH key for reviewer
if [ ! -f ~/.ssh/reviewer ]; then
  ssh-keygen -t rsa -b 4096 -f ~/.ssh/reviewer -N ""
fi

# Initialize Terraform
cd ../terraform
terraform init \
  -backend-config="bucket=${BUCKET_NAME}" \
  -backend-config="prefix=terraform/state"

# Apply Terraform configuration
terraform apply -auto-approve

# Get server IPs
LDAP_SERVER_IP=$(terraform output -raw ldap_server_ip)
APP_SERVER_IP=$(terraform output -raw app_server_ip)

# Export IPs for Ansible
export LDAP_SERVER_IP
export APP_SERVER_IP


# Update .env file with new IPs
cd ../scripts
echo "Updating .env file..."
sed -i "s/^LDAP_SERVER_IP=.*/LDAP_SERVER_IP=$LDAP_SERVER_IP/" .env
sed -i "s/^APP_SERVER_IP=.*/APP_SERVER_IP=$APP_SERVER_IP/" .env

echo "Environment file updated successfully!"

# Wait for instances to be ready
echo "Waiting for instances to be ready..."
sleep 60

# Run Ansible playbooks
cd ../ansible

# Export environment variables for Ansible
export ANSIBLE_HOST_KEY_CHECKING=False
export ANSIBLE_SSH_ARGS="-o StrictHostKeyChecking=no"

# Run playbooks with environment variables
IPA_ADMIN_PASSWORD=$IPA_ADMIN_PASSWORD \
IPA_DS_PASSWORD=$IPA_DS_PASSWORD \
USER1_PASSWORD=$USER1_PASSWORD \
USER2_PASSWORD=$USER2_PASSWORD \
USER3_PASSWORD=$USER3_PASSWORD \
REVIEWER_PASSWORD=$REVIEWER_PASSWORD \
IPA_DOMAIN=$IPA_DOMAIN \
IPA_SHORT=$IPA_SHORT \
IPA_REALM=$IPA_REALM \
LDAP_SERVER_IP=$LDAP_SERVER_IP \
APP_SERVER_IP=$APP_SERVER_IP \
ansible-playbook playbooks/ldap_setup.yml -vv 


IPA_ADMIN_PASSWORD=$IPA_ADMIN_PASSWORD \
IPA_DOMAIN=$IPA_DOMAIN \
IPA_REALM=$IPA_REALM \
LDAP_SERVER_IP=$LDAP_SERVER_IP \
APP_SERVER_IP=$APP_SERVER_IP \
ansible-playbook playbooks/app_setup.yml -vv

echo "Environment creation completed successfully!"
echo "LDAP Server IP: $LDAP_SERVER_IP"
echo "App Server IP: $APP_SERVER_IP" 