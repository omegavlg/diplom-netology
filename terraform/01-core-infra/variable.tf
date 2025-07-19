variable "cloud_id" {
  type        = string
  description = "cloud_id"
}

variable "folder_id" {
  type        = string
  description = "folder_id"
}

variable "zone_a" {
  type        = string
  default     = "ru-central1-a"
  description = "ru-central1-a"
}

variable "zone_b" {
  type        = string
  default     = "ru-central1-b"
  description = "ru-central1-b"
}

variable "access_key" {
  description = "Access key for Object Storage"
  type        = string
}

variable "secret_key" {
  description = "Secret key for Object Storage"
  type        = string
}

variable "service_account_id" {
  description = "Service Account ID"
  type        = string
}

variable "metadata" {
  type        = map(string)
  description = "Metadata VM"
}

variable "preemptible" {
  type        = bool
  default     = true
  description = "Whether the VM is preemptible."
}