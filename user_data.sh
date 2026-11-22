#!/bin/bash
# עדכון רשימת החבילות והתקנת כלים להורדה מאובטחת (HTTPS)
sudo apt update -y
sudo apt install -y ca-certificates curl

# יצירת תיקיית מפתחות והורדת מפתח ה-GPG הרשמי של Docker לאימות החבילות
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# הוספת המאגר (Repository) הרשמי של Docker למקורות ההתקנה של Ubuntu
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# עדכון מחדש והתקנת מנוע ה-Docker והתוספים (Compose ו-Buildx)
sudo apt update -y
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# הפעלת שירות ה-Docker מידית והגדרתו לעלות אוטומטית בכל אתחול של השרת
sudo systemctl enable --now docker

# צירוף המשתמש ubuntu לקבוצת docker כדי להריץ פקודות ללא צורך ב-sudo
sudo usermod -aG docker ubuntu