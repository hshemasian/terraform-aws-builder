variable "vpc_id" {
  description = "The ID of the VPC where the security group will be created"
  type        = string
}


variable "instance_type" {
  description = "EC2 Instance type"
  type        = string
}


variable "ami_id" {
  description = "EC2 Instance type ami id"
  type        = string
}


variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
}


variable "public_subnet_id" {
  description = "The ID of the public subnet where the EC2 instance will launch"
  type        = string
}