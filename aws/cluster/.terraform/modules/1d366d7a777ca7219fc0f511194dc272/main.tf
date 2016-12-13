variable "cluster_name" {}
variable "region" {}

resource "aws_s3_bucket" "kubernetes-assets" {
  bucket = "${var.cluster_name}-kubernetes-assets"
  acl = "private"

  tags {
      Name = "${var.cluster_name}-kubernetes-assets"
  }

  provisioner "local-exec" {
    command = "for i in $(ls ../../../certs/*gz); do echo aws s3 cp $i s3://${var.cluster_name}-kubernetes-assets/ssl/ --region ${var.region}; done"
  }
}
