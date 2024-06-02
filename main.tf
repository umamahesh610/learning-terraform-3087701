data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["bitnami-tomcat-*-x86_64-hvm-ebs-nami"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["979382823631"] # Bitnami
}

data "aws_vpc" "default"{
  default=true
}

module "blog_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "dev"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]


  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

resource "aws_instance" "blog" {
  ami           = data.aws_ami.app_ami.id
  instance_type = var.instance_type

  vpc_security_group_ids = [module.blog_sg.security_group_id]

  subnet_id     = module.blog_vpc.public_subnets[0]

  tags = {
    Name = "HelloWorld"
  }
}

module "autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "7.5.0"
  
  name     = "blog-autoscaling"
  min_size = 1
  max_size = 2

  vpc_zone_identifier = module.blog_vpc.public_subnets
  target_group_arns   = [aws_lb_target_group.blog-alb-tg.arn]
  security_groups     = [module.blog_sg.security_group_id]

  image_id      = data.aws_ami.app_ami.id
  instance_type = var.instance_type

  tag_specifications = [
    {
      resource_type = "instance"
      tags          = { WhatAmI = "Instance" }
    },
    {
      resource_type = "volume"
      tags          = { WhatAmI = "Volume" }
    }
  ]

  tags = {
    Environment = "dev"
    Project     = "megasecret"
  }

}

resource "aws_lb_target_group" "blog-alb-tg" {
  name     = "blog-alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.blog_vpc.vpc_id
}

#resource "aws_lb_target_group_attachment" "blog-alb-tg-att1" {
#  target_group_arn = aws_lb_target_group.blog-alb-tg.arn
#  target_id        = aws_instance.blog.id
#  port             = 80
#}

resource "aws_lb" "blog-alb" {
  name               = "blog-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.blog_sg.security_group_id]
  subnets            = module.blog_vpc.public_subnets
}

resource "aws_lb_listener" "blog-alb-listener" {
  load_balancer_arn = aws_lb.blog-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blog-alb-tg.arn
  }
}

module "blog_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.2"
  name    = "blog"

  vpc_id = module.blog_vpc.vpc_id

  ingress_rules       =  ["http-80-tcp","https-443-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"] 

  egress_rules       = ["all-all"]
  egress_cidr_blocks = ["0.0.0.0/0"] 

}