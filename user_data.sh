#!/bin/bash
# עצירת הסקריפט מיד אם פקודה נכשלת, משתנה לא מוגדר או פקודה בתוך pipe נכשלת
set -euo pipefail

# הגדרת נתיב לכלים ומפתח הגישה לקלאסטר עבור ההרצה הנוכחית
export PATH=$PATH:/usr/local/bin
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# התקנת K3s עם הרשאת קריאה (644) לקובץ הקונפיגורציה גם למשתמש ubuntu
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--write-kubeconfig-mode 644" sh -

# שמירת המשתנה KUBECONFIG עבור חיבורי SSH עתידיים של המשתמש ubuntu
echo 'export KUBECONFIG=/etc/rancher/k3s/k3s.yaml' >> /home/ubuntu/.bashrc

# המתנה עד שה-Node של K3s עובר למצב Ready (הרווח לפני Ready מונע זיהוי שגוי של NotReady)
until kubectl get nodes 2>/dev/null | grep -q " Ready"; do
  echo "Waiting for K3s node to be Ready..."
  sleep 5
done

# התקנת Helm (מנהל החבילות של Kubernetes)
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# יצירת Namespace בשם argocd והתקנת ArgoCD בתוכו
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply --server-side -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# המתנה עד ששרת הממשק של ArgoCD מסיים לעלות
kubectl -n argocd rollout status deployment/argocd-server --timeout=300s

# חשיפת ממשק הווב של ArgoCD החוצה באמצעות NodePort (פורט 30443 ל-HTTPS)
kubectl -n argocd patch svc argocd-server -p '{"spec": {"type": "NodePort", "ports": [{"name": "http", "port": 80, "targetPort": 8080, "nodePort": 30080}, {"name": "https", "port": 443, "targetPort": 8080, "nodePort": 30443}]}}'

# הגדרת אפליקציית GitOps שתחבר את ArgoCD לריפוזיטורי שלך עם סנכרון אוטומטי
cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: gitops-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/hshemasian/gitops.git
    targetRevision: HEAD
    path: .
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF