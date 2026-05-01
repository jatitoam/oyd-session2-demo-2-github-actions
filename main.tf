resource "aws_ssm_parameter" "app_version" {
  name  = "/${var.app_name}/${var.environment}/version"
  type  = "String"
  value = var.app_version

  tags = {
    environment = var.environment
    managed_by  = "terraform"
  }
}
