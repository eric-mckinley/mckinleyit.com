provider "aws" {
  version = "~> 2.0"
  region  = "eu-west-2"
}

provider "aws"  {
  alias = "virginia"
  region = "us-east-1"
}
terraform {
  backend "s3" {
    bucket = "mckinleyit-tfstate"
    key    = "states/websites"
    region = "eu-west-2"
  }
}

resource "aws_s3_bucket" "website" {
  bucket = "${var.www_domain_name}"
  acl    = "public-read"
  policy = <<POLICY
{
  "Version":"2012-10-17",
  "Statement":[
    {
      "Sid":"AddPerm",
      "Effect":"Allow",
      "Principal": "*",
      "Action":["s3:GetObject"],
      "Resource":["arn:aws:s3:::${var.www_domain_name}/*"]
    }
  ]
}
POLICY

  website {
    index_document = "index.html"
    error_document = "404.html"
  }
}

resource "aws_acm_certificate" "certificate" {
  domain_name = "*.${var.root_domain_name}"
  validation_method = "EMAIL"

  subject_alternative_names = [
    "${var.root_domain_name}"]
  provider = "aws.virginia"
}


resource "aws_cloudfront_distribution" "www_distribution" {
  origin {
    custom_origin_config {
      // These are all the defaults.
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }

    domain_name = "${aws_s3_bucket.website.website_endpoint}"
    // This can be any name to identify this origin.
    origin_id   = "${var.www_domain_name}"
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "${var.www_domain_name}"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  aliases = ["${var.www_domain_name}"]

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = "${aws_acm_certificate.certificate.arn}"
    ssl_support_method  = "sni-only"
  }
}

resource "aws_route53_zone" "zone" {
  name = "${var.root_domain_name}"
}

resource "aws_route53_record" "www" {
  zone_id = "${aws_route53_zone.zone.zone_id}"
  name    = "${var.www_domain_name}"
  type    = "A"

  alias  {
    name                   = "${aws_cloudfront_distribution.www_distribution.domain_name}"
    zone_id                = "${aws_cloudfront_distribution.www_distribution.hosted_zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "email" {
  zone_id = "${aws_route53_zone.zone.zone_id}"
  name    = "${var.root_domain_name}"
  type    = "MX"
  ttl     = "300"
  records = [
    "${var.mx1}",
    "${var.mx2}",
    "${var.mx3}",
  ]
}