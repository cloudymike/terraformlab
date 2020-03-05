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
              if [ ${var.production} ]; then
                echo certbot --nginx -n --agree-tos -d "${var.subdomain}.${var.domain}" -m "admin.${var.domain}"
              else
                certbot --nginx -n --agree-tos -d "${var.subdomain}.${var.domain}" -m "admin.${var.domain}" --test-cert
              fi
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

resource "aws_route53_record" dns_name {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "${var.subdomain}.${var.domain}"
  type    = "A"
  ttl     = "60"
  records = ["${aws_instance.example.public_ip}"]
}


######################### Data
data "aws_route53_zone" "selected" {
  name         = "${var.domain}."
  private_zone = false
}


variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 8080
}

variable "domain" {
  description = "hosted zone domain"
  type        = string
  default     = "hopitty.com"
}

variable "subdomain" {
  description = "subdomain or server name"
  type        = string
  default     = "testme"
}

variable "production" {
  description = "If it is a production deploy"
  type        = bool
  default     = false
}

output "public_ip" {
  value       = aws_instance.example.public_ip
  description = "The public IP address of the web server"
}




# TODO 
#  Parameterize hostname, domain and subdomain
#  Parameter if certbot is a testrun (staging)
#  Follow book setup
#  letsencrypt/ACME with terraform? 
#    https://www.terraform.io/docs/providers/acme/dns_providers/acme-dns.html


