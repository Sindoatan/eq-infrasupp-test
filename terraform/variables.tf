variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "ldap_server_name" {
  description = "Name of the LDAP server instance"
  type        = string
  default     = "ldap-server"
}

variable "app_server_name" {
  description = "Name of the application server instance"
  type        = string
  default     = "app-server"
}

variable "machine_type" {
  description = "Machine type for the instances"
  type        = string
  default     = "e2-medium"
}

variable "ldap_boot_disk_size" {
  description = "Boot disk size for LDAP server in GB"
  type        = number
  default     = 20
}

variable "app_boot_disk_size" {
  description = "Boot disk size for app server in GB"
  type        = number
  default     = 20
}

variable "app_data_disk_size" {
  description = "Data disk size for app server in GB"
  type        = number
  default     = 20
}

variable "network_name" {
  description = "Name of the VPC network"
  type        = string
  default     = "test-lab-vpc"
}

variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
  default     = "test-lab-subnet"
}

variable "subnet_cidr" {
  description = "CIDR range for the subnet"
  type        = string
  default     = "10.0.0.0/24"
}

variable "bucket_name" {
  description = "The name of the GCS bucket for Terraform state"
  type        = string
} 