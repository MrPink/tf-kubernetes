provider "aws" {
  region = "${var.region}"
}

module "vpc" {
  source              = "../modules/vpc"
  name                = "kubernetes"
  cidr                = "${var.vpc_cidr_block}"
  private_subnets     = "10.0.1.0/24,10.0.2.0/24"
  public_subnets      = "10.0.101.0/24,10.0.102.0/24"
  bastion_instance_id = "${aws_instance.bastion.id}"
  availability_zones  = "${var.availability_zones}"
}

# ssh keypair for instances
module "aws-ssh" {
  source = "../modules/ssh"
  public_key_file = "${var.public_key_file}"
  private_key_file = "${var.private_key_file}"
}

module "iam" { source = "../modules/iam" }

# security group to allow all traffic in and out of the instances in the VPC
module "sg-default" {
  source = "../modules/sg-traffic"

  vpc_id = "${module.vpc.vpc_id}"
}

module "route53" {
  source = "../modules/route53"
  vpc_id = "${module.vpc.vpc_id}"
  cluster_name = "${var.cluster_name}"
  environment = "${var.environment}"
}

# Generate an etcd URL for the cluster
resource "null_resource" "etcd_discovery_url" {
  provisioner "local-exec" {
    command = "curl https://discovery.etcd.io/new?size=${var.masters} > ${var.etcd_discovery_url_file}"
  }
}

# outputs
output "bastion.ip" {
  value = "${aws_eip.bastion.public_ip}"
}
output "vpc_cidr_block_ip" {
 value = "${module.vpc.vpc_cidr_block}"
}
