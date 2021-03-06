module "master_amitype" {
  source        = "github.com/terraform-community-modules/tf_aws_virttype"
  instance_type = "${var.master_instance_type}"
}

module "master_ami" {
  source   = "github.com/terraform-community-modules/tf_aws_coreos_ami"
  region   = "${var.region}"
  channel  = "${var.coreos_channel}"
  virttype = "${module.master_amitype.prefer_hvm}"
}

data "template_file" "master_cloud_init" {
  template   = "${file("master-cloud-config.yml.tpl")}"
  depends_on = ["null_resource.etcd_discovery_url"]
  vars {
    cluster_name = "${var.cluster_name}"
    region       = "${var.region}"
  }
}

resource "aws_launch_configuration" "master-config" {
  instance_type     = "${var.master_instance_type}"
  name              = "master-config"
  image_id          = "${module.master_ami.ami_id}"
  count             = "${var.masters}"
  key_name          = "${module.aws-ssh.keypair_name}"
  security_groups   = ["${module.sg-default.security_group_id}"]
  user_data         = "${data.template_file.master_cloud_init.rendered}"
  associate_public_ip_address = false
  iam_instance_profile = "${module.iam.master_profile_name}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "master-group" {
  launch_configuration = "master-config"
  max_size = "${var.az_count}"
  min_size = "${var.az_count}"
  desired_capacity = "${var.az_count}"
  vpc_zone_identifier = ["${module.vpc.private_subnets}"]
  load_balancers = ["${aws_elb.internal-api.id}"]

  tag {
    key = "Name"
    value = "kube-master"
    propagate_at_launch = true
  }
}

resource "aws_elb" "internal-api" {

  name = "kubernetes-api-internal"
  cross_zone_load_balancing = true
  availability_zones = ["${var.availability_zones}"]
  internal = true
  security_groups   = ["${module.sg-default.security_group_id}"]

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "TCP:6443"
    interval = 30
  }

  tags {
    Name = "api-internal"
  }

  "listener" {
    instance_port = 6443
    instance_protocol = "TCP"
    lb_port = 443
    lb_protocol = "TCP"
  }
}

