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
  filename        = "${path.root}/builder-key.pem"
  content         = tls_private_key.ec2_key.private_key_pem
  file_permission = "0400"
}


# ==========================================
# 2. חומת אש ברמת המכונה (Security Group)
# ==========================================

# מגדיר חוקי תעבורה נכנסת (Ingress) ויוצאת (Egress) — פועל כ-Stateful Firewall
resource "aws_security_group" "builder_sg" {
  name        = "builder_sg"
  description = "Allow SSH and Flask access"
  vpc_id      = var.vpc_id

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
  # תעבורה נכנסת: גישה לממשק הווב של ArgoCD על פורט NodePort 30443
  ingress {
    description = "Allow ArgoCD UI (HTTPS)"
    from_port   = 30443
    to_port     = 30443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ==========================================
# 3. הקמת שרת ה-EC2 והרצת סקריפט אתחול
# ==========================================

resource "aws_instance" "builder" {
  ami                         = var.ami_id                         # מערכת ההפעלה
  instance_type               = var.instance_type                  # גודל/סוג השרת
  vpc_security_group_ids      = [aws_security_group.builder_sg.id] # שיוך חומת האש
  subnet_id                   = var.public_subnet_id               # מיקום השרת בתוך הרשת הציבורית
  key_name                    = aws_key_pair.deployer.key_name     # שיוך מפתח ה-SSH הציבורי
  user_data                   = file("${path.root}/user_data.sh")  # קריאת סקריפט ההתקנה החיצוני
  user_data_replace_on_change = true                               # יצירת השרת מחדש אם סקריפט ה-user_data שונה

  tags = {
    Name = var.instance_name
  }
}