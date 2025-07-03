# Deploy the App of Apps to existing ArgoCD
resource "kubectl_manifest" "app_of_apps" {
  yaml_body = file("${path.module}/../../argocd-apps/app-of-apps.yaml")
}