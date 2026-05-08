resource "aws_route53_record" "app" {
  count   = var.route53_zone_id != "" && var.domain_name != "" ? 1 : 0
  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"
  ttl     = 60
  records = [var.records_ip]
}

resource "aws_route53_record" "status" {
  count   = var.route53_zone_id != "" && var.domain_name != "" ? 1 : 0
  zone_id = var.route53_zone_id
  name    = var.status_domain
  type    = "A"
  ttl     = 60
  records = [var.records_ip]
}
