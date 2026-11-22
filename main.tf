# ==========================================
# 1. ניהול מפתחות SSH (הצפנה אסימטרית)
# ==========================================

# יוצר זוג מפתחות (פרטי וציבורי) בהצפנה אסימטרית מסוג RSA באורך 4096 ביט
resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# מעלה את המפתח הציבורי ל-AWS כדי שהשרת יזהה ויאשר אותנו בהתחברות
resource "aws_key_pair" "deployer" {
  key_name   = "builder-key"
  public_key = tls_private_key.ec2_key.public_key_openssh
}

# שומר את המפתח הפרטי אצלנו במחשב המקומי עם הרשאת קריאה לבעלים בלבד (0400 - חובה ב-SSH)
resource "local_file" "ssh_key_file" {
  filename        = "${path.module}/builder-key.pem"
  content         = tls_private_key.ec2_key.private_key_pem
  file_permission = "0400"
}

# ==========================================
# 2. הקמת רשת וירטואלית פרטית (VPC)
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

# ==========================================
# 3. חומת אש ברמת המכונה (Security Group)
# ==========================================

# מגדיר חוקי תעבורה נכנסת (Ingress) ויוצאת (Egress) — פועל כ-Stateful Firewall
resource "aws_security_group" "builder_sg" {
  name        = "builder_sg"
  description = "Allow SSH and Flask access"
  vpc_id      = aws_vpc.public_vpc.id

  tags = {
    Name = "builder_sg"
  }

  # תעבורה יוצאת: מאפשר לשרת לגשת החוצה לכל כתובת ובכל פרוטוקול (נדרש להורדת חבילות ו-Docker)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # תעבורה נכנסת 1: פותח פורט 22 עבור התחברות מרחוק ב-SSH
  ingress {
    description = "Allow SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # תעבורה נכנסת 2: פותח פורט 5001 עבור גישה לאפליקציית ה-Web / Flask שנריץ על השרת
  ingress {
    description = "Allow Flask app access"
    from_port   = 5001
    to_port     = 5001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ==========================================
# 4. הקמת שרת ה-EC2 והרצת סקריפט אתחול
# ==========================================

resource "aws_instance" "builder" {
  ami                         = var.ami_id                          # מערכת ההפעלה
  instance_type               = var.instance_type                   # גודל/סוג השרת
  vpc_security_group_ids      = [aws_security_group.builder_sg.id]  # שיוך חומת האש
  subnet_id                   = aws_subnet.public_subnet.id         # מיקום השרת בתוך הרשת הציבורית
  key_name                    = aws_key_pair.deployer.key_name      # שיוך מפתח ה-SSH הציבורי
  user_data                   = file("${path.module}/user_data.sh") # קריאת סקריפט ההתקנה החיצוני
  user_data_replace_on_change = true                                # יצירת השרת מחדש אם סקריפט ה-user_data שונה

  tags = {
    Name = var.instance_name
  }
}