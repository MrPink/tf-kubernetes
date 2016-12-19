module "worker_amitype" {
  source        = "github.com/terraform-community-modules/tf_aws_virttype"
  instance_type = "${var.worker_instance_type}"
}

module "worker_ami" {
  source   = "github.com/terraform-community-modules/tf_aws_coreos_ami"
  region   = "${var.region}"
  channel  = "${var.coreos_channel}"
  virttype = "${module.worker_amitype.prefer_hvm}"
}

resource "template_file" "worker_cloud_init" {
  template   = "worker-cloud-config.yml.tpl"
  depends_on = ["template_file.etcd_discovery_url"]
  vars {
    cluster_name = "${var.cluster_name}"
    region       = "${var.region}"
  }
}

resource "aws_launch_configuration" "worker-lc-config" {
  instance_type     = "${var.worker_instance_type}"
  ami               = "${module.worker_ami.ami_id}"
  name_prefix       = "node-"
  key_name          = "${aws_key_pair.kube-node-key.key_name}"
  key_name          = "${module.aws-ssh.keypair_name}"
  security_groups   = ["${module.sg-default.security_group_id}"]
  #iam_instance_profile = "${}"
  associate_public_ip_address = false
  user_data         = "${template_file.worker_cloud_init.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "worker-as-group" {

  launch_configuration = "${aws_launch_configuration.worker-lc-config.id}"
  max_size = "${var.az_count * 10}"
  min_size = "${var.az_count}"
  desired_capacity = "${var.az_count}"
  vpc_zone_identifier = ["${module.vpc.private_subnets}"]

  tag {
    key = "Name"
    value = "kube-worker"
    propagate_at_launch = true
  }
}

resource "aws_elb" "ingress" {

  name = "kubernetes-ingress"
  cross_zone_load_balancing = true
  vpc_zone_identifier = ["${module.vpc.public_subnets}"]
  security_groups   = ["${module.sg-default.security_group_id}"]

  tags {
    Name = "ingress"
  }

  "listener" {
    instance_port = 80
    instance_protocol = "HTTP"
    lb_port = 80
    lb_protocol = "HTTP"
  }
}

