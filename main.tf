# Provider for eu-central-1 (Frankfurt) region
provider "aws" {
  region     = "eu-central-1"
  access_key = var.aws_access_key
  secret_key = var.aws_access_secret
}

# Provider for eu-west-1 (Ireland) region
provider "aws" {
  alias      = "eu_west_1" # Give an alias to differentiate this provider from the other one
  region     = "eu-west-1"
  access_key = var.aws_access_key
  secret_key = var.aws_access_secret
}

# Create VPC in eu-central-1 region
resource "aws_vpc" "main_eu_central" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "uptime-monitor-eu-central-vpc"
  }
}

# Create VPC in eu-west-1 region
resource "aws_vpc" "main_eu_west" {
  provider   = aws.eu_west_1
  cidr_block = "10.1.0.0/16"
  tags = {
    Name = "uptime-monitor-eu-west-vpc"
  }
}

# Create Subnets in Different AZs in eu-central-1 region
resource "aws_subnet" "subnet_a_eu_central" {
  vpc_id            = aws_vpc.main_eu_central.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-central-1a"
}

resource "aws_subnet" "subnet_b_eu_central" {
  vpc_id            = aws_vpc.main_eu_central.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-central-1b"
}

# Create Subnets in Different AZs in eu-west-1 region
resource "aws_subnet" "subnet_a_eu_west" {
  provider          = aws.eu_west_1
  vpc_id            = aws_vpc.main_eu_west.id
  cidr_block        = "10.1.1.0/24"
  availability_zone = "eu-west-1a"
}

resource "aws_subnet" "subnet_b_eu_west" {
  provider          = aws.eu_west_1
  vpc_id            = aws_vpc.main_eu_west.id
  cidr_block        = "10.1.2.0/24"
  availability_zone = "eu-west-1b"
}

# Create Web Server Instances in Different AZs in eu-central-1 region
resource "aws_instance" "webserver_a_eu_central" {
  ami           = "ami-08defee0641d1f168" # Replace with the AMI ID for your desired operating system in eu-central-1
  instance_type = "t4g.nano"
  subnet_id     = aws_subnet.subnet_a_eu_central.id

  # Add other necessary configurations like security groups, tags, etc.
}

resource "aws_instance" "webserver_b_eu_central" {
  ami           = "ami-08defee0641d1f168" # Replace with the AMI ID for your desired operating system in eu-central-1
  instance_type = "t4g.nano"
  subnet_id     = aws_subnet.subnet_b_eu_central.id

  # Add other necessary configurations like security groups, tags, etc.
}

# Create Web Server Instances in Different AZs in eu-west-1 region
resource "aws_instance" "webserver_a_eu_west" {
  provider      = aws.eu_west_1
  ami           = "ami-0fa19619b49993b72" # Replace with the AMI ID for your desired operating system in eu-west-1
  instance_type = "t4g.nano"
  subnet_id     = aws_subnet.subnet_a_eu_west.id

  # Add other necessary configurations like security groups, tags, etc.
}

resource "aws_instance" "webserver_b_eu_west" {
  provider      = aws.eu_west_1
  ami           = "ami-0fa19619b49993b72" # Replace with the AMI ID for your desired operating system in eu-west-1
  instance_type = "t4g.nano"
  subnet_id     = aws_subnet.subnet_b_eu_west.id

  # Add other necessary configurations like security groups, tags, etc.
}

# Create Load Balancer
resource "aws_lb" "load_balancer" {
  name               = "multi-site-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]

  subnets = [
    aws_subnet.subnet_a_eu_central.id,
    aws_subnet.subnet_a_eu_west.id,
  ]
}

# Create Security Group for Load Balancer
resource "aws_security_group" "lb_sg" {
  name_prefix = "lb_sg-"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Attach Load Balancer Target Groups to Instances
resource "aws_lb_target_group_attachment" "attachment_eu_central" {
  target_group_arn = aws_lb_target_group.target_group_eu_central.arn
  target_id        = aws_instance.webserver_a_eu_central.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "attachment_eu_west" {
  target_group_arn = aws_lb_target_group.target_group_eu_west.arn
  target_id        = aws_instance.webserver_a_eu_west.id
  port             = 80
}

# Create Target Groups
resource "aws_lb_target_group" "target_group_eu_central" {
  name     = "target-group-eu-central"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main_eu_central.id
}

resource "aws_lb_target_group" "target_group_eu_west" {
  name     = "target-group-eu-west"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main_eu_west.id
}

# Create Listener for Load Balancer
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group_eu_central.arn
  }
}
