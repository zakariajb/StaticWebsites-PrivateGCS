# Reserve a global static IP for the Load Balancer
resource "google_compute_global_address" "static_ip" {
  name = "${var.name}-lb-static-ip"
}


# Create a Global Internet NEG pointing to the Cloud Storage bucket
resource "google_compute_global_network_endpoint_group" "global_neg" {
  name                  = "${var.name}-global-internet-neg"
  default_port          = 443 # HTTPS for Cloud Storage access
  network_endpoint_type = "INTERNET_FQDN_PORT"

}
resource "google_compute_global_network_endpoint" "endpoint" {
  global_network_endpoint_group = google_compute_global_network_endpoint_group.global_neg.name
  fqdn                          = "${var.name}-${random_id.bucket_suffix.hex}.storage.googleapis.com"
  port                          = 443
}

# Backend Service with CDN enabled, using the Global Internet NEG
resource "google_compute_backend_service" "backend_service" {
  provider               = google-beta
  name                   = "${var.name}-neg-backend"
  load_balancing_scheme  = "EXTERNAL_MANAGED"
  protocol               = "HTTPS"
  timeout_sec            = 30
  custom_request_headers = ["host: ${google_compute_global_network_endpoint.endpoint.fqdn}"]
  backend {
    group = google_compute_global_network_endpoint_group.global_neg.id
  }
  enable_cdn = true
  cdn_policy {
    cache_key_policy {
      include_protocol     = false
      include_host         = true
      include_query_string = true
    }
    cache_mode = "FORCE_CACHE_ALL"


  }

  security_settings {
    aws_v4_authentication {
      access_key_id = google_storage_hmac_key.key.access_id
      access_key    = google_storage_hmac_key.key.secret
      origin_region = var.region
    }
  }
}

# URL Map with advanced routing rules
resource "google_compute_url_map" "url_map" {
  provider        = google-beta
  name            = "${var.name}-lb"
  default_service = google_compute_backend_service.backend_service.id

  host_rule {
    hosts        = ["site2.poc.poc.com"]
    path_matcher = "site2matcher"
  }
  host_rule {
    hosts        = ["site1.poc.poc.com"]
    path_matcher = "site1matcher"
  }

  path_matcher {
    name            = "site2matcher"
    default_service = google_compute_backend_service.backend_service.id


    default_custom_error_response_policy {
      error_response_rule {
        match_response_codes   = ["404"]
        override_response_code = 200
        path                   = "/site2/error2.html"
      }
      error_service = google_compute_backend_service.backend_service.id

    }

    route_rules {
      priority = 1
      match_rules {
        prefix_match = "/"
      }
      route_action {
        weighted_backend_services {
          backend_service = google_compute_backend_service.backend_service.id
          weight          = 100
        }
        url_rewrite {
          path_prefix_rewrite = "/site2/site2.html"
        }
      }
    }
  }

  path_matcher {
    name            = "site1matcher"
    default_service = google_compute_backend_service.backend_service.id


    default_custom_error_response_policy {
      error_response_rule {
        match_response_codes   = ["404"]
        override_response_code = 200
        path                   = "/site1/error1.html"
      }
      error_service = google_compute_backend_service.backend_service.id

    }

    route_rules {
      priority = 1
      match_rules {
        prefix_match = "/"
      }
      route_action {
        weighted_backend_services {
          backend_service = google_compute_backend_service.backend_service.id
          weight          = 100
        }
        url_rewrite {
          path_prefix_rewrite = "/site1/site1.html"
        }
      }
    }
  }
}

# HTTP Proxy for Load Balancer
resource "google_compute_target_http_proxy" "http_proxy" {
  name    = "http-proxy"
  url_map = google_compute_url_map.url_map.id
}

# Global Forwarding Rule for HTTP with the reserved static IP
resource "google_compute_global_forwarding_rule" "http_forwarding_rule" {
  name                  = "http-forwarding-rule"
  ip_address            = google_compute_global_address.static_ip.address
  target                = google_compute_target_http_proxy.http_proxy.id
  port_range            = "80"
  load_balancing_scheme = "EXTERNAL_MANAGED"
}
