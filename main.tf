provider "aws" {
    region = "us-east-1"
  
}




/*variable "multi-az-deployment" {
  description = "create a standby DB instance"
  type = bool
  default = "false"
}

variable vpc_cidr_block {}
variable env_prefix {}
variable instance_type {}
variable database_name {}
variable database_username {}
variable database_user_password {}
variable ami {}
variable keyname {}
variable db_RDS {}*/


data "aws_availability_zones" "available" {
  state = "available"
}


resource "aws_vpc" "prod_vpc2" {
  cidr_block = var.vpc_cidr_block
  enable_dns_hostnames = true
  tags = {
    Name: "${var.env_prefix}-vpc"
  }  
}

resource "aws_subnet" "subnet-1" {
  vpc_id = aws_vpc.prod_vpc2.id
  cidr_block = var.subnets_cidr_blocks[0]
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name: "${var.env_prefix}-subnet-1"
  }  
}
resource "aws_subnet" "subnet-2" {
  vpc_id = aws_vpc.prod_vpc2.id
  cidr_block = var.subnets_cidr_blocks[1]
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name: "${var.env_prefix}-subnet-2"
  }  
}

resource "aws_subnet" "subnet-3" {
  vpc_id = aws_vpc.prod_vpc2.id
  cidr_block = var.subnets_cidr_blocks[2]
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    Name: "${var.env_prefix}-subnet-3"
  }  
}


resource "aws_internet_gateway" "viti-gw" {
  vpc_id = aws_vpc.prod_vpc2.id

  tags = {
    Name = "${var.env_prefix}-gw"
  }
}

resource "aws_route_table" "viti-route-1" {
  vpc_id = aws_vpc.prod_vpc2.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.viti-gw.id
  }

    tags = {
    Name = "${var.env_prefix}-rtb"
   }
}

resource "aws_route_table_association" "viti-rtb-ass" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.viti-route-1.id
}


resource "aws_instance" "viti_instance" {
  ami           = var.ami
  instance_type = var.instance_type
  key_name      = var.keyname
  security_groups = ["${aws_security_group.viti-web.id}"]
  subnet_id = aws_subnet.subnet-1.id
  associate_public_ip_address = "true"
  user_data = data.template_file.user_data.rendered

}

output "instance_public_ip" {
  value = aws_instance.viti_instance.public_ip
}

output "public_dns" {
  description = "wordpress url"
  value       = aws_instance.viti_instance.public_dns
}
#security group
resource "aws_security_group" "viti-web" {
  name = "viti-web"
  description = "Web Security Group"
  vpc_id      = aws_vpc.prod_vpc2.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }    
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags  = {
    name = "web server SG"
  }
}

# SG for RDS
resource "aws_security_group" "RDST-SG" {
  name = "RDST-SG"
  description = "RDS Security Group"
  vpc_id      = aws_vpc.prod_vpc2.id

  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    security_groups = ["${aws_security_group.viti-web.id}"]
  }
  
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_db_instance" "wordpressdb" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  db_name              = var.database_name
  username             = var.db_username
  password             = "var.database_password"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
  db_subnet_group_name = aws_db_subnet_group.viti2_Db_group.name
  #multi_az             = ["${var.multi-az-deployment}"]
  vpc_security_group_ids = [aws_security_group.RDST-SG.id]
}  

resource "aws_db_subnet_group" "viti2_Db_group" {
  name       = "viti_database_subnets"
  subnet_ids = [aws_subnet.subnet-2.id,aws_subnet.subnet-3.id]

  tags = {
    Name = "My_DB_subnet group"
  }
}

resource "aws_kms_key" "terra-bucket-key" {
 description             = "This key is used to encrypt bucket objects"
 deletion_window_in_days = 10
 enable_key_rotation     = true
}

resource "aws_kms_alias" "keykey-alias" {
 name          = "alias/terra-bucket-key"
 target_key_id = aws_kms_key.terra-bucket-key.key_id
}

resource "aws_s3_bucket" "terra-state" {
  bucket = "terraviti"
}

resource "aws_s3_bucket_acl" "example" {
  bucket = aws_s3_bucket.terra-state.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.terra-state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "block" {
 bucket = aws_s3_bucket.terra-state.id

 block_public_acls       = true
 block_public_policy     = true
 ignore_public_acls      = true
 restrict_public_buckets = true
}

