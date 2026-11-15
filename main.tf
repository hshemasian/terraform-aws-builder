#---------ssh-------

resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}


resource "aws_key_pair" "deployer" {
  key_name   = "builder-key"
  public_key = tls_private_key.ec2_key.public_key_openssh
}


resource "local_file" "ssh_key_file" {
  filename        = "${path.module}/builder-key.pem"
  content         = tls_private_key.ec2_key.private_key_pem
  file_permission = "0400" # הרשאות קריאה בלבד לבעל הקובץ (מאובטח)
}

#-----------vpc----------


resource "aws_vpc" "public_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "builder-vpc"
  }
}


resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.public_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true # מקצה IP ציבורי אוטומטית למכונות ברשת זו

  tags = {
    Name = "public-subnet"
  }
}
/*

# resource "aws_subnet" "private_subnet" {
#   vpc_id            = aws_vpc.public_vpc.id
#   cidr_block        = "10.0.2.0/24"
#   availability_zone = "us-east-1a"

#   tags = {
#     Name = "private-subnet"
#   }
# }
*/

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.public_vpc.id

  tags = {
    Name = "main-igw"
  }
}


resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.public_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}


resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

#--------security_group----------


resource "aws_security_group" "builder_sg" {
  name        = "builder_sg"
  description = "Allow SSH and Flask access"
  vpc_id      = aws_vpc.public_vpc.id

  tags = {
    Name = "builder_sg"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow SSH and Flask access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow http and Flask access"
    from_port   = 5001
    to_port     = 5001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#------------ec2-----------

resource "aws_instance" "builder" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.builder_sg.id]
  subnet_id              = aws_subnet.public_subnet.id
  key_name               = aws_key_pair.deployer.key_name
  tags = {
    Name = var.instance_name
  }
}
