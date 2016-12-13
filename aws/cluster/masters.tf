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

resource "template_file" "master_cloud_init" {
  template   = "master-cloud-config.yml.tpl"
  #depends_on = ["template_file.etcd_discovery_url"]
  vars {
    cluster_name = "${var.cluster_name}"
    region       = "${var.region}"
  }
}

resource "aws_instance" "master" {
  instance_type     = "${var.master_instance_type}"
  ami               = "${module.master_ami.ami_id}"
  count             = "${var.masters}"
  key_name          = "${module.aws-ssh.keypair_name}"
  source_dest_check = false
  subnet_id         = "${element(split(",", module.vpc.private_subnets), count.index)}"
  vpc_security_group_ids = ["${module.sg-default.security_group_id}"]
  depends_on        = ["aws_instance.bastion"]
  user_data         = "${template_file.master_cloud_init.rendered}"
  tags = {
    Name = "kube-master-${count.index}"
    ansibleNodeType = "master"
    ansibleFilter = "bouncer"
  }
  connection {
    user                = "${var.default_instance_user}"
    private_key         = "${file("${var.private_key_file}")}"
    bastion_host        = "${aws_eip.bastion.public_ip}"
    bastion_private_key = "${file("${var.private_key_file}")}"
  }

  # Do some early bootstrapping of the CoreOS machines. This will install
  # python and pip so we can use as the ansible_python_interpreter in our playbooks
  provisioner "file" {
    source      = "../../scripts/coreos"
    destination = "/tmp"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo chmod -R +x /tmp/coreos",
      "/tmp/coreos/bootstrap.sh",
      "~/bin/python /tmp/coreos/get-pip.py",
      "sudo mv /tmp/coreos/runner ~/bin/pip && sudo chmod 0755 ~/bin/pip",
      "sudo rm -rf /tmp/coreos"
    ]
  }
}

resource "aws_route53_record" "kube-masters-internal" {
  zone_id = "${module.route53.zone_id}"
  count = "${var.masters}"
  name = "kube_master_${count.index}"
  type = "A"
  ttl = 5
  records = ["${element(aws_instance.master.*.private_ip, count.index)}"]
}
