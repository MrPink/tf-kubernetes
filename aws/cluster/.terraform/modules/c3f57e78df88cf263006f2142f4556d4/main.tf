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

# Generate ../ssh/ssh.cfg
data "template_file" "ssh_cfg" {
    template = "${file("../templates/ssh.cfg")}"
    vars {
      region = "${var.region}"
      default_instance_user = "${var.default_instance_user}"
      cluster_name = "${var.cluster_name}"
      master0_ip = "${var.master0_ip}"
      master1_ip = "${var.master1_ip}"
      worker0_ip = "${var.worker0_ip}"
    }
}
resource "null_resource" "ssh_cfg" {
  triggers {
    template_rendered = "${ data.template_file.ssh_cfg.rendered }"
  }
  provisioner "local-exec" {
    command = "echo '${ data.template_file.ssh_cfg.rendered }' > ../../../ssh/ssh.cfg"
  }
}
