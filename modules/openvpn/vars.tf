#
# Module level variables.  Typically no defaults are given here,
# because it is expected they will be overridden at module
# instantiation
variable "aws_region" {
  description = "AWS Region for deploying resources into"
  type        = "string"
}

// Useful for instantiating multiple VPN servers in the same
// AWS account.  This will be attached directly to i.e. the
// instance name, so use i.e. "-dev".
variable "deployment_suffix" {
  type        = "string"
  default     = ""
  description = "Optional suffix to append to differentiate separate VPN instances"
}

variable "ami" {
  type        = "string"
  description = "AMI to use for VPN server"
}

variable "instance_type" {
  type        = "string"
  description = "AWS instance type to use"
}

variable "aws_profile" {
  type        = "string"
  description = "AWS profile to use"
}

variable "aws_az" {
  description = "AWS availability zone"
  type        = "string"
}

variable "pub_key" {
  type        = "string"
  description = "pub key"
}
