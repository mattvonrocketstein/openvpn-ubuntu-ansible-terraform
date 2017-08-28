provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

module "openvpn" {
  source        = "modules/openvpn"
  instance_type = "t2.micro"
  ami           = "${var.ami}"
  aws_region    = "${var.aws_region}"
  aws_profile   = "${var.aws_profile}"
  aws_az        = "${var.aws_az}"
  pub_key       = "${var.pub_key}"
}

output "ip" {
  value = "${module.openvpn.ip}"
}
