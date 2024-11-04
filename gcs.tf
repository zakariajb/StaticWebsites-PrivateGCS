# Create new storage bucket in the EU multi-region
resource "random_id" "bucket_suffix" {
  byte_length = 2
}

resource "google_storage_bucket" "static" {
  name     = "${var.name}-${random_id.bucket_suffix.hex}"
  location = "EU"

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
}


# Create a new service account
resource "google_service_account" "service_account" {
  account_id = "bs-private-access"
}

# Grant Access to view objects in the bucket
resource "google_storage_bucket_iam_binding" "binding" {    
  bucket = google_storage_bucket.static.name
  role   = "roles/storage.objectViewer"
  members = [
    google_service_account.service_account.member,
  ]
}
# Create the HMAC key for the associated service account
resource "google_storage_hmac_key" "key" {
  service_account_email = google_service_account.service_account.email
}

