variable "environment" {
  description = "The environment"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet ids"
}

variable "vpc_id" {
  description = "The VPC id"
}

//variable "allowed_security_group_id" {
//  description = "The allowed security group id to connect on RDS"
//}

variable "allocated_storage" {
  default     = "20"
  description = "The storage size in GB"
}

variable "instance_class" {
  description = "The instance type"
}

variable "multi_az" {
  default     = true
  description = "Muti-az allowed?"
}

variable "database_name" {
  description = "The database name"
}

variable "database_username" {
  description = "The username of the database"
}

variable "database_password" {
  description = "The password of the database"
}

variable "backup_retention_period" {
  description = "The days to retain backups for"
  type        = number
  default     = 7
}
