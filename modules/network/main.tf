# ==========================================
#  הקמת רשת וירטואלית פרטית (VPC)
# ==========================================

# יוצר את הרשת הראשית שלנו בענן עם טווח כתובות פנימי (65,536 כתובות) ותמיכה בשמות DNS
resource "aws_vpc" "public_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "builder-vpc"
  }
}

# יוצר תת-רשת (Subnet) בתוך ה-VPC עם טווח של 256 כתובות והקצאת IP ציבורי אוטומטית לכל מכונה
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.public_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

/*
# דוגמה לתת-רשת פרטית (ללא IP ציבורי אוטומטי) למקרה שנרצה להוסיף בעתיד מסד נתונים מבודד
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.public_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "private-subnet"
  }
}
*/

# יוצר שער אינטרנט (Internet Gateway) שמאפשר תקשורת דו-כיוונית בין ה-VPC לאינטרנט
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.public_vpc.id

  tags = {
    Name = "main-igw"
  }
}

# יוצר טבלת ניתוב (Route Table) שמפנה כל תעבורה שמיועדת החוצה (0.0.0.0/0) אל שער האינטרנט
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

# מחבר את טבלת הניתוב אל תת-הרשת (Subnet) — הפעולה שהופכת אותה בפועל לרשת ציבורית
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}