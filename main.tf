variable "db_user_password" {}

provider "aws" {

    region = "${var.aws_region}"

}

variable "aws_region" {

    description = "Region for the VPC"
    default = "us-east-2"

}

variable "vpc_cidr" {

    description = "CIDR for the VPC"
    default = "10.77.0.0/16"

}

variable "ssh_keys" {

    description = "SSH public keys"
    default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDXkrXvB6eYbWqwoAWM3YJa5vLhW+83A1c4vinSbVVdxUsLTFgceKY9Ur7q0EIkFYetFkoLz5hnUgaPFOSuYEnVuHL9L7hT7y5RHL+pJBwBLcmkymmGTCI1+2lbBGru09+IvyW7HSNOxkojVTmcsN9v294CSuwHKj7QJ2FRuCo9G6lwfHhCJHLPr2E7X9wJcHCKwlpUoLdIHO6+5OQbEiyPBp4A46NeLWq/1cMJiv9catMb4EBO8LcOhpqGzsqcthEKSZj/R28JrPWHfsBV3dQ2PUgHPts0OP+ilJZSwGWZV8GYl+25TfuveiVI7Zqhj00dUycvLeRGiiYssK4zuVhjv0DALMOjcybp326F8zIvruYU/DPernBWSi10nA+foUFMruAZ5TcCUt1dIVzywbqJKBgHaYOTg87FnCwsY9gLbZB0ZcQzPrsfhaviEfPKF01Gba69t2XD4J+FgmZu0JE1IfPktaCIZtfaU/IipUNvrmS0KpkW93mmQ/r6JCSNKcKEhwbkjJBOXURtfgoKV3PGHCp+B7RHSjysAAOP4vSnnuaGa/pHAeq/fBBzQeD62whgvVwDUGHL/rBXHeQeF49PryZ06nV/LDFFmudac5dzIDK19zZ+o4mwAF7E8wxilb2WenmRwKwD0DqkEEhp6j1+J7rfUsqzo2DS/j/GDDf6aQ==\nssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCyINkK+qDhRJkZeZZcCSZa4N+H+WHuzBI/NfWBl0H3zBboyJg/PnFlV+2uzvi4QmnW8ueZkxC+KAs0Dt1ZWvoDMryFHbBPGe2p5p2mzQhT5nSuGHgkNotZ7r19RuZo47oq0QcSuO9dOSfAziVB1JdIJ9nuMC1UXJCjWCyayM1ZSaFBfXaDG624JH+QLSr28RD6ZqnRHE0ZfhO0eBOmGeDKOhp3ml2FURuY0srJHePg2w5/VJBR1JOop/7F2o9d/128YOjGj+/rtxZBq1BXphJ/KWzg8GbiB5H86u/GVd2IbyvsXRXgYFBh0Ep8sugTgSAMIdGlpkAq5o9qMUbcxOVx"

}

variable "public_subnet_cidr_zone_a" {

    description = "CIDR for the public subnet in Zone A"
    default = "10.77.0.0/20"

}

variable "public_subnet_cidr_zone_b" {

    description = "CIDR for the public subnet in Zone B"
    default = "10.77.16.0/20"

}


resource "aws_vpc" "scandiweb0" {

    cidr_block = "${var.vpc_cidr}"

    enable_dns_hostnames = true

    tags {
        Name = "scandiweb0"
    }

}

resource "aws_subnet" "scandiweb01" {

    vpc_id = "${aws_vpc.scandiweb0.id}"
    cidr_block = "${var.public_subnet_cidr_zone_a}"
    availability_zone = "${var.aws_region}a"
    map_public_ip_on_launch = true

    tags {
        Name = "scandiweb01"
    }

}

resource "aws_subnet" "scandiweb02" {

    vpc_id = "${aws_vpc.scandiweb0.id}"
    cidr_block = "${var.public_subnet_cidr_zone_b}"
    availability_zone = "${var.aws_region}b"
    map_public_ip_on_launch = true


    tags {
        Name = "scandiweb02"
    }

}

resource "aws_internet_gateway" "scandiweb0" {

    vpc_id = "${aws_vpc.scandiweb0.id}"

    tags {
        Name = "scandiweb0"
    }

}

resource "aws_route_table" "scandiweb01" {

    vpc_id = "${aws_vpc.scandiweb0.id}"
    tags {
        Name = "scandiweb01"
    }   
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.scandiweb0.id}"
    }

}

resource "aws_route_table" "scandiweb02" {

    vpc_id = "${aws_vpc.scandiweb0.id}"
    tags {
        Name = "scandiweb02"
    }   
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.scandiweb0.id}"
    }

}

resource "aws_route_table_association" "scandiweb01" {

     subnet_id = "${aws_subnet.scandiweb01.id}"
     route_table_id = "${aws_route_table.scandiweb01.id}"

}

resource "aws_route_table_association" "scandiweb02" {

     subnet_id = "${aws_subnet.scandiweb02.id}"
     route_table_id = "${aws_route_table.scandiweb02.id}"

}

resource "aws_instance" "scandiweb_magento" {

    ami = "ami-0f65671a86f061fcd" 
    instance_type = "t2.micro"
    key_name = "scandiweb"
    subnet_id = "${aws_subnet.scandiweb01.id}"

    tags {
        Name = "scandiweb_magento"
    }

    provisioner "file" {
        source      = "provision-magento.sh"
        destination = "/tmp/provision-magento.sh"
        connection {
            user        = "ubuntu"
            private_key = "${file("scandiweb.pem")}"
        }
    }

    provisioner "remote-exec" {
        inline = [
            "echo \"${var.ssh_keys}\" >> /home/ubuntu/.ssh/authorized_keys",
            "chmod +x /tmp/provision-magento.sh",
            "sudo /tmp/provision-magento.sh ${var.db_user_password}",
        ]
        connection {
            user        = "ubuntu"
            private_key = "${file("scandiweb.pem")}"
        }
    }

    vpc_security_group_ids = ["${aws_security_group.magento.id}"]

}

resource "aws_security_group" "magento" {

    name = "magento"
    vpc_id = "${aws_vpc.scandiweb0.id}"

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["${var.vpc_cidr}"]

    }
    egress {

        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]

    }

}

resource "aws_instance" "scandiweb_varnish" {

    ami = "ami-0f65671a86f061fcd" 
    instance_type = "t2.micro"
    subnet_id = "${aws_subnet.scandiweb01.id}"
    key_name = "scandiweb"

    tags {
        Name = "scandiweb_varnish"
    }

    provisioner "file" {
        source      = "provision-varnish.sh"
        destination = "/tmp/provision-varnish.sh"
        connection {
            user        = "ubuntu"
            private_key = "${file("scandiweb.pem")}"
        }
    }

    provisioner "remote-exec" {
        inline = [
            "echo \"${var.ssh_keys}\" >> /home/ubuntu/.ssh/authorized_keys",
            "chmod +x /tmp/provision-varnish.sh",
            "sudo /tmp/provision-varnish.sh ${aws_instance.scandiweb_magento.private_dns}",
        ]
        connection {
            user        = "ubuntu"
            private_key = "${file("scandiweb.pem")}"
        }
    }

    vpc_security_group_ids = ["${aws_security_group.varnish.id}"]

}

resource "aws_security_group" "varnish" {

    name = "varnish"
    vpc_id = "${aws_vpc.scandiweb0.id}"

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["${var.vpc_cidr}"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

}

resource "aws_alb" "scandiweb" {

    name = "scandiweb"
    internal = false
    security_groups = ["${aws_security_group.alb.id}"]
    subnets = ["${aws_subnet.scandiweb01.id}", "${aws_subnet.scandiweb02.id}"]
    enable_deletion_protection = true

}


resource "aws_security_group" "alb" {

    name = "alb"

    vpc_id = "${aws_vpc.scandiweb0.id}"

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

}

resource "aws_alb_target_group" "varnish" {

	name = "varnish"
	vpc_id = "${aws_vpc.scandiweb0.id}"
	port = "80"
	protocol = "HTTP"

}

resource "aws_alb_target_group" "magento" {

	name = "magento"
	vpc_id = "${aws_vpc.scandiweb0.id}"
	port = "80"
	protocol = "HTTP"

}

resource "aws_alb_listener" "http" {

	load_balancer_arn = "${aws_alb.scandiweb.arn}"
	port = "80"
	protocol = "HTTP"

    default_action {
        type = "redirect"

        redirect {
            port = "443"
            protocol = "HTTPS"
            status_code = "HTTP_301"
        }
    }

}

resource "aws_alb_listener" "https" {

	load_balancer_arn = "${aws_alb.scandiweb.arn}"
	port = "443"
	protocol = "HTTPS"
	ssl_policy = "ELBSecurityPolicy-2016-08"
	certificate_arn = "arn:aws:acm:us-east-2:162813680020:certificate/528b79e0-b461-45ac-9fb8-69c98e1298e1"

	default_action {
		target_group_arn = "${aws_alb_target_group.varnish.arn}"
		type = "forward"
	}

}

resource "aws_alb_listener_rule" "static" {

    listener_arn = "${aws_alb_listener.https.arn}"
    priority = 100

    action {
        type = "forward"
        target_group_arn = "${aws_alb_target_group.magento.arn}"
    }

    condition {
        field = "path-pattern"
        values = ["/static/*"]
    }

}

resource "aws_alb_listener_rule" "media" {

    listener_arn = "${aws_alb_listener.https.arn}"
    priority = 101

    action {
        type = "forward"
        target_group_arn = "${aws_alb_target_group.magento.arn}"
    }

    condition {
        field = "path-pattern"
        values = ["/media/*"]
    }

}

resource "aws_alb_target_group_attachment" "varnish" {

    target_group_arn = "${aws_alb_target_group.varnish.arn}"
    target_id = "${aws_instance.scandiweb_varnish.id}"
    port = 80

}

resource "aws_alb_target_group_attachment" "magento" {

    target_group_arn = "${aws_alb_target_group.magento.arn}"
    target_id = "${aws_instance.scandiweb_magento.id}"
    port = 80

}

