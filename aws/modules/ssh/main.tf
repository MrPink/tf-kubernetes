# input variables
variable "short_name" { default = "kube" }
variable "public_key_file" {}
variable "private_key_file" {}
variable "default_instance_user" {}
variable "region" {}
variable "master0_ip" {}
variable "master1_ip" {}
variable "worker0_ip" {}
variable "cluster_name" {}

# SSH keypair for the instances
resource "aws_key_pair" "default" {
  key_name   = "${var.short_name}"
	public_key = "${file("${var.public_key_file}")}"
}

# output variables
output "keypair_name" {
  value = "${aws_key_pair.default.key_name}"
}
