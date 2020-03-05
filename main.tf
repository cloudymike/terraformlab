provider "aws" {
  region = "us-east-2"
}

resource "aws_instance" "example" {
  ami = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

# TODO: These should be created later
  key_name = "mikael"
  iam_instance_profile = "kmsdns"

  vpc_security_group_ids = [
      aws_security_group.instance.id,
      aws_security_group.ssh.id,
  ]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get -y install awscli
              apt-get -y install nginx
              apt-get install -y software-properties-common
              add-apt-repository -y universe
              add-apt-repository -y ppa:certbot/certbot
              apt-get update
              apt-get install -y certbot python-certbot-nginx
              certbot --nginx -n --agree-tos -d 'testme.hopitty.com' -m 'hakansso@pacbell.net' --test-cert
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF
  tags = {
    Name = "terraform-example"
  }
}

resource "aws_security_group" "instance" {
  name = "terraform-example-instance"
  
  ingress {
    from_port      = 80
    to_port        = 80
    protocol       = "tcp"
    cidr_blocks    = ["0.0.0.0/0"]
  }
  ingress {
    from_port      = 443
    to_port        = 443
    protocol       = "tcp"
    cidr_blocks    = ["0.0.0.0/0"]
  }
  ingress {
    from_port      = var.server_port
    to_port        = var.server_port
    protocol       = "tcp"
    cidr_blocks    = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ssh" {
  name = "ssh-example"
  
  ingress {
    from_port      = 22
    to_port        = 22
    protocol       = "tcp"
    cidr_blocks    = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_route53_record" "testme" {
  zone_id = var.hosted_zone_id
  name    = "testme.hopitty.com"
  type    = "A"
  ttl     = "60"
  records = ["${aws_instance.example.public_ip}"]
}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 8080
}

variable "hosted_zone_id" {
  description = "The hosted zone to use for dns"
  type        = string
  default     = "Z35WUM7D19XEYL"
}

output "public_ip" {
  value       = aws_instance.example.public_ip
  description = "The public IP address of the web server"
}

# TODO 
#  Parameterize hostname, domain and subdomain
#  Parameter if certbot is a testrun (staging)
#  Either domain or domain id should be derived
#  Follow book setup



