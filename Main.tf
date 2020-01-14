# Terraform state will be stored in S3
terraform {
  backend "s3" {
    bucket = "ecs-test-1990"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}

# Use AWS Terraform provider
provider "aws" {
  region = "us-east-1"
}

# VPC
resource "aws_vpc" "ecs-vpc" {
  cidr_block           = var.vpc_cidr_block
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  enable_classiclink   = "false"
  tags = {
    Name = "ecs-vpc"
  }
}

# Public Subnets 1
resource "aws_subnet" "ecs-public-1" {
  vpc_id                  = aws_vpc.ecs-vpc.id
  cidr_block              = var.public1_subnet_cidr_block
  map_public_ip_on_launch = "true"
  availability_zone       = "us-east-1a"

  tags = {
    Name = "ecs-public-1"
  }
}


#Public Subnets 2
resource "aws_subnet" "ecs-public-2" {
    vpc_id     = aws_vpc.ecs-vpc.id
    cidr_block = var.public2_subnet_cidr_block
    map_public_ip_on_launch = "true"
    availability_zone       = "us-east-1b"

  tags = {
    Name = "ecs-public-2"
  }
}


#Private Subnet 1
resource "aws_subnet" "ecs-private-1" {
    vpc_id     = aws_vpc.ecs-vpc.id
    cidr_block = var.private1_subnet_cidr_block
    map_public_ip_on_launch = "false"
    availability_zone = "us-east-1c"

    tags = {
        Name = "ecs-private-1"
    }
}

#Private Subnet 2
resource "aws_subnet" "ecs-private-2" {
    vpc_id     = aws_vpc.ecs-vpc.id
    cidr_block = var.private2_subnet_cidr_block
    map_public_ip_on_launch = "false"
    availability_zone = "us-east-1d"

    tags = {
        Name = "ecs-private-2"
    }
}

# Internet Gateway
resource "aws_internet_gateway" "ecs-vpc-internet-gateway" {
  vpc_id = aws_vpc.ecs-vpc.id

  tags = {
    Name = "ecs-vpc-internet-gateway"
  }
}

# Route Tables public
resource "aws_route_table" "ecs-vpc-route-table" {
  vpc_id = aws_vpc.ecs-vpc.id

  route {
    cidr_block = "10.0.0.0/0"
    gateway_id = aws_internet_gateway.ecs-vpc-internet-gateway.id
  }

  tags = {
    Name = "ecs-vpc-route-table"
  }
}

resource "aws_route_table_association" "ecs-vpc-route-table-association1" {
  subnet_id      = aws_subnet.ecs-public-1.id
  route_table_id = aws_route_table.ecs-vpc-route-table.id
}

resource "aws_route_table_association" "demo-vpc-route-table-association2" {
  subnet_id      = aws_subnet.ecs-public-2.id
  route_table_id = aws_route_table.ecs-vpc-route-table.id
}

#Network ACL
resource "aws_network_acl" "ecs-vpc-network-acl" {
    vpc_id = aws_vpc.ecs-vpc.id
    subnet_ids = [aws_subnet.ecs-public-1.id, aws_subnet.ecs-public-2.id]

    egress {
        protocol   = "-1"
        rule_no    = 100
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 0
        to_port    = 0
    }

    ingress {
        protocol   = "-1"
        rule_no    = 100
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 0
        to_port    = 0
    }

    tags = {
        Name = "ecs-vpc-network-acl"
    }
}

#NAT
resource "aws_eip" "ecs-eip" {
vpc      = true
}
resource "aws_nat_gateway" "ecs-nat-gw" {
allocation_id = aws_eip.ecs-eip.id
subnet_id = aws_subnet.ecs-public-1.id
depends_on = [aws_internet_gateway.ecs-vpc-internet-gateway]
}

# Terraform Training VPC for NAT
resource "aws_route_table" "ecs-private" {
    vpc_id = aws_vpc.ecs-vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.ecs-nat-gw.id
    }

    tags = {
        Name = "ecs-private-1"
    }
}

#Route Tables public using NAT
resource "aws_route_table_association" "ecs-private1" {
    subnet_id = aws_subnet.ecs-private-1.id
    route_table_id = aws_route_table.ecs-private.id
}

resource "aws_route_table_association" "ecs-private2" {
    subnet_id = aws_subnet.ecs-private-2.id
    route_table_id = aws_route_table.ecs-private.id
}

#SG
resource "aws_security_group" "ecs-securitygroup" {
  description = "controls direct access to application instances"
  vpc_id      = aws_vpc.ecs-vpc.id
  name        = "ecs"

  ingress {
    protocol  = "tcp"
    from_port = 22
    to_port   = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    protocol  = "tcp"
    from_port = 32768
    to_port   = 61000
    security_groups = [aws_security_group.myapp-elb-securitygroup.id]
  }
  
  ingress {
    protocol  = "tcp"
    from_port = 8080
    to_port   = 8080
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    protocol  = "tcp"
    from_port = 443
    to_port   = 443
    cidr_blocks = ["0.0.0.0/0"]
  }
  

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.myapp-elb-securitygroup.id]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "myapp-elb-securitygroup" {
  vpc_id      = aws_vpc.ecs-vpc.id
  name        = "myapp-elb"
  description = "security group for ecs"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "myapp-elb"
  }
}

#autoscaling
resource "aws_autoscaling_group" "ecs-test-autoscaling" {
  name                 = "ecs-test-autoscaling"
  vpc_zone_identifier  = [aws_subnet.ecs-public-1.id, aws_subnet.ecs-public-2.id]
  min_size             = var.autoscale_min
  max_size             = var.autoscale_max
  desired_capacity     = var.autoscale_desired
  launch_configuration = aws_launch_configuration.ecs-test-launchconfig.name
}

data "template_file" "cloud_config" {
  template = file("cloud-config.yml")

  vars = {
    aws_region         = var.aws_region
    ecs_cluster_name   = aws_ecs_cluster.test-cluster.name
    ecs_log_level      = "info"
    ecs_agent_version  = "latest"
    ecs_log_group_name = aws_cloudwatch_log_group.ecs.name
  }
}

data "aws_ami" "stable_coreos" {
  most_recent = true

  filter {
    name   = "description"
    values = ["CoreOS Container Linux stable *"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["595879546273"] # CoreOS
}

resource "aws_launch_configuration" "ecs-test-launchconfig" {
  name_prefix                 = "ecs-launch"
  security_groups             = [aws_security_group.ecs-securitygroup.id]
  key_name                    = var.key_name
  image_id                    = data.aws_ami.stable_coreos.id
  instance_type               = var.ecs_Instance_type
  iam_instance_profile        = aws_iam_instance_profile.app.name
  user_data                   = data.template_file.cloud_config.rendered
  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }
}


## ECS

resource "aws_ecs_cluster" "test-cluster" {
  name = "test-cluster"
}

data "template_file" "task_definition" {
  template = file("task-definition.json")
  
  vars = {
    image_url        = "git+https://github.com/fhinkel/nodejs-hello-world.git"
    container_name   = "nodejs-hello-world"
    log_group_region = var.aws_region
    log_group_name   = aws_cloudwatch_log_group.app.name
  }
}

resource "aws_ecs_task_definition" "nodejs-hello-world" {
  family                = "tf_example_ghost_td"
  container_definitions = data.template_file.task_definition.rendered
}

resource "aws_ecs_service" "test" {
  name            = "tf-example-ecs-ghost"
  cluster         = aws_ecs_cluster.test-cluster.id
  task_definition = aws_ecs_task_definition.nodejs-hello-world.arn
  desired_count   = var.autoscale_desired
  iam_role        = aws_iam_role.ecs_service.name

  load_balancer {
    target_group_arn = aws_alb_target_group.test.id
    container_name   = "nodejs-hello-world"
    container_port   = "80"
      
  }

  depends_on = [aws_iam_role_policy.ecs_service, aws_alb_listener.front_end]
  
}

## ALB

resource "aws_alb_target_group" "test" {
  name     = "tf-example-ecs-ghost"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.ecs-vpc.id
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    path                = "/"
    interval            = 30
  }
}

resource "aws_alb" "main" {
  name            = "tf-example-alb-ecs"
  subnets         = [aws_subnet.ecs-public-1.id, aws_subnet.ecs-public-2.id]
  security_groups = [aws_security_group.myapp-elb-securitygroup.id]
}

resource "aws_alb_listener" "front_end" {
  load_balancer_arn = aws_alb.main.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.test.id
    type             = "forward"
  }
}  

## CloudWatch Logs

resource "aws_cloudwatch_log_group" "ecs" {
  name = "tf-ecs-group/ecs-agent"
}

resource "aws_cloudwatch_log_group" "app" {
  name = "tf-ecs-group/app-ghost"
}

## IAM

resource "aws_iam_role" "ecs_service" {
  name = "tf_example_ecs_role"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "ecs_service" {
  name = "tf_example_ecs_policy"
  role = aws_iam_role.ecs_service.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:Describe*",
        "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
        "elasticloadbalancing:DeregisterTargets",
        "elasticloadbalancing:Describe*",
        "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
        "elasticloadbalancing:RegisterTargets"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "app" {
  name = "tf-ecs-instprofile"
  role = aws_iam_role.app_instance.name
}

resource "aws_iam_role" "app_instance" {
  name = "tf-ecs-example-instance-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

data "template_file" "instance_profile" {
  template = file("instance-profile-policy.json")

  vars = {
    app_log_group_arn = aws_cloudwatch_log_group.app.arn
    ecs_log_group_arn = aws_cloudwatch_log_group.ecs.arn
  }
}

resource "aws_iam_role_policy" "instance" {
  name   = "TfEcsExampleInstanceRole"
  role   = aws_iam_role.app_instance.name
  policy = data.template_file.instance_profile.rendered
}
