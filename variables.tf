# האזור הגיאוגרפי ב-AWS שבו יוקמו כל המשאבים (אליו מתחבר ה-Provider)
variable "aws_region" {
  description = "AWS Region to deploy resources"
  type        = string
  default     = "us-east-1"
}

/*
# דוגמה למשתנה של VPC קיים (מושבת כרגע כי אנחנו יוצרים VPC חדש מאפס)
variable "vpc_id" {
  description = "The ID of the existing AWS VPC"
  type        = string
  default     = "vpc-044604d0bfb707142"
}
*/

# סוג המכונה (קובע כמות מעבדים וזיכרון RAM; t3.micro חסכוני ומתאים לתרגול)
variable "instance_type" {
  description = "EC2 Instance type"
  type        = string
  default     = "t3.small"
}

# מזהה תמונת מערכת ההפעלה (AMI) של Ubuntu באזור us-east-1
variable "ami_id" {
  description = "EC2 Instance type ami id"
  type        = string
  default     = "ami-0547ecbf0e9b4aeb5"
}

# תגית השם (Name Tag) שתופיע בלוח הבקרה של AWS עבור השרת
variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
  default     = "builder"
}

# מרכז הנתונים הפיזי (Availability Zone) בתוך ה-Region שבו תשב תת-הרשת
variable "availability_zone" {
  description = "Availability Zone for the public subnet"
  type        = string
  default     = "us-east-1a"
}