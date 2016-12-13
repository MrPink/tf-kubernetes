variable "cluster_name" {}
variable "environment" {}
variable "vpc_id" {}

resource "aws_route53_zone" "private" {
  name = "${var.cluster_name}.tv"
  vpc_id = "${var.vpc_id}"

  tags {
    Role = "${var.environment}"
  }
}

output "zone_id" {
  value = "${aws_route53_zone.private.zone_id}"
}
