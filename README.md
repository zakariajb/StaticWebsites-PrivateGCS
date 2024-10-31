# GCP Secure Static Website Hosting with Terraform

This Terraform configuration deploys a secure static website hosted on a private Google Cloud Storage (GCS) bucket. The setup serves content via Cloud CDN using Google Cloud Platform's Network Endpoint Group (NEG) and external Application Load Balancer (ALB). Authentication with HMAC keys allows secure access to private content while utilizing Cloud CDN for optimal performance.


## Prerequisites

- **Terraform** version >= 0.12
- **Google Cloud SDK** with an authenticated account and appropriate permissions
- **GCP Project** with billing enabled
- **Google Cloud Storage API** and **Compute Engine API** enabled in your project

## Resources Created

- **Google Cloud Storage Bucket** (Private): Stores static website files.
- **Service Account**: Provides access to the GCS bucket via HMAC keys.
- **HMAC Key**: Used by the backend service to authenticate with GCS.
- **Network Endpoint Group (NEG)**: Configured to have the GCS API as an endpoint.
- **External Application Load Balancer (HTTP(S) Load Balancer)**
- **Cloud CDN**: Configured to cache content from the GCS bucket.
