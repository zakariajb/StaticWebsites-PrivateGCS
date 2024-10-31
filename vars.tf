variable "name" {
  type        = string
  default     = "tf-poc"
  description = "name used as prefix for bucket, bs, and lb"
}

variable "region" {
  type        = string
  default     = "europe-west9"
  description = "region used"
}