variable "cluster_name" {}
variable "environment" {}
variable "vpc_id" {}

resource "aws_route53_zone" "private" {
  name = "${replace("${var.cluster_name}", "-${var.environment}", "")}"
  vpc_id = "${var.vpc_id}"

  tags {
    Role = "${var.environment}"
  }
}

output "zone_id" {
  value = "${aws_route53_zone.private.zone_id}"
}