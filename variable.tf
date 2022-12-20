/*variable vpc_cidr_block {}
variable env_prefix {}
variable instance_type {}
variable database_name {}
variable database_username {}
variable database_user_password {}
variable ami {}
variable keyname {}
variable db_RDS {}*/

variable "subnets_cidr_blocks" {
    type = list (string)
    description = "subnets cidr blocks"
}
variable "vpc_cidr_block" {
    type = string
    description = "vpc cidr blocks"
}
variable "env_prefix" {
    type = string
    description = "environment prefix"
}
variable "instance_type" {
    type = string
    description = "instance type"
    default = "t2.micro"
}

variable "database_name" {
    type = string
    description = "database name"
}
variable "db_username" {
    type = string
    description = "database username"
}

variable "database_user_password" {
    type = string
    description = "database password"
}

variable "ami" {
    type = string
    description = "latest ami"
}

variable "keyname" {
    type = string
    description = "key pair"
}

variable "db_RDS" {
    type = string
    description = "rds endpoint"
    default = "aws_db_instance.wordpressdb.endpoint"
}




