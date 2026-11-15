#---------ssh-------
# 1. יצירת המפתח הפרטי בתוך Terraform
resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# 2. יצירת Key Pair ב-AWS באמצעות המפתח הציבורי שנוצר למעלה
resource "aws_key_pair" "deployer" {
  key_name   = "builder-key"
  public_key = tls_private_key.ec2_key.public_key_openssh
}

# 3. שמירת המפתח הפרטי כקובץ מקומי במחשב שלך (כדי שתוכל להשתמש בו ב-SSH)
resource "local_file" "ssh_key_file" {
  filename        = "${path.module}/builder-key.pem"
  content         = tls_private_key.ec2_key.private_key_pem
  file_permission = "0400" # הרשאות קריאה בלבד לבעל הקובץ (מאובטח)
}

#-----------vpc----------

#יצירת vpc
resource "aws_vpc" "public_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "builder-vpc"
  }
}

# 2. יצירת רשת משנה ציבורית (Public Subnet)
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
# 3. יצירת רשת משנה פרטית (Private Subnet)
# resource "aws_subnet" "private_subnet" {
#   vpc_id            = aws_vpc.public_vpc.id
#   cidr_block        = "10.0.2.0/24"
#   availability_zone = "us-east-1a"

#   tags = {
#     Name = "private-subnet"
#   }
# }
*/
# 4. יצירת שער אינטרנט (Internet Gateway) לחיבור הרשת הציבורית לעולם
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.public_vpc.id

  tags = {
    Name = "main-igw"
  }
}

# 5. יצירת טבלת ניתוב (Route Table) עבור הרשת הציבורית
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

# 6. שיוך טבלת הניתוב לרשת הציבורית
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