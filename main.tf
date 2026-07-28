provider "aws" {
  region = "eu-north-1"
}
resource "aws_instance" "terraform" {
  ami = "ami-00de9383c964b0448"
  instance_type="t3.micro"
   vpc_security_group_ids = [aws_security_group.instance.id]

    user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF
    user_data_replace_on_change = true

  tags ={
    Name: "terraform"
  }
}

//create the bucket to store the terraform state file
resource "aws_s3_bucket" "terraform-bkt" {
  bucket = "tform-bkt-66"

  lifecycle {
    prevent_destroy = true
  }
}
resource "aws_security_group" "instance" {
  name = "terraform-security-group"
  
  ingress {
    from_port = 8080 
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

} 