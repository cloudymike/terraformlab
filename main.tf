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

  user_data = data.template_file.user_data.rendered
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


######################### Data #########################
data "aws_route53_zone" "selected" {
  name         = "${var.domain}."
  private_zone = false
}

data "template_file" "user_data" {
  template = file("user_data.sh")
  vars = {
    domain = var.domain
    subdomain = var.subdomain
    release_type = var.release_type
  }
}

######################### vars #########################

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

variable "release_type" {
  description = "If it is a production deploy"
  type        = string
  default     = "development"
}

output "public_ip" {
  value       = aws_instance.example.public_ip
  description = "The public IP address of the web server"
}




# TODO 
#  Follow book setup
# TODO: These should be created later
#   key_name = "mikael"
#   iam_instance_profile = "kmsdns"
# TODO Setup network, vpc etc.
# TODO setup git download and web server
# TODO setup aws access to file
# TODO AWS mqtt, and remove local mqtt installed, and handle keys through aws
# TODO link certs to a fixed name and make nginx config server name agnostic

