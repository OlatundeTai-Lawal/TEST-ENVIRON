data "template_file" "user_data" {
   template = "${file("${path.module}/Viti.sh")}"
    vars = {
      db_username      = var.db_username
      db_user_password = var.database_user_password
      database_name         = var.database_name
      db_RDS           = aws_db_instance.wordpressdb.endpoint
		      
     }
}

