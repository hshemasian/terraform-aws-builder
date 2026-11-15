variable "aws_region" {
  description = "AWS Region to deploy resources"
  type        = string
  default     = "us-east-1"
}
/*
variable "vpc_id" {
  description = "The ID of the existing AWS VPC"
  type        = string
  default     = "vpc-044604d0bfb707142"
}
*/
variable "instance_type" {
  description = "EC2 Instance type"
  type        = string
  default     = "t3.micro"
}


variable "ami_id" {
  description = "EC2 Instance type ami id"
  type        = string
  default     = "ami-0547ecbf0e9b4aeb5"
}


variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
  default     = "builder"
}