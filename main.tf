provider "aws" {
  region = "ap-southeast-2"
}

resource "aws_launch_template" "lt-home" {
  name_prefix   = "lt-home"
  image_id      = "ami-0ba8d27d35e9915fb"   # change if needed
  instance_type = "t3.micro"
  key_name      = "k8s"          # change

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = ["sg-058caa1639a688167"]
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "Hello from Auto Scaling Instance" > /var/www/html/index.html
              EOF
  )
}

# ----------------------------
# Target Group
# ----------------------------
resource "aws_lb_target_group" "home-tg" {
  name        = "home-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = "vpc-068d87d7493a0870c"
  target_type = "instance"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    interval            = 30
    timeout             = 5
  }
}

# ----------------------------
# Application Load Balancer
# ----------------------------
resource "aws_lb" "alb" {
  name               = "home-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["sg-058caa1639a688167"]

  subnets = [
    "subnet-0480420dfd34c4770",
    "subnet-086d579e9e69d29a5",
    "subnet-0b3bcfd70df2ede06"
  ]
}

# ----------------------------
# Listener
# ----------------------------
resource "aws_lb_listener" "alb-listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.home-tg.arn
  }
}

# ----------------------------
# Auto Scaling Group
# ----------------------------
resource "aws_autoscaling_group" "asg-home" {
  name                      = "asg-home"
  desired_capacity          = 1
  max_size                  = 1
  min_size                  = 1
  vpc_zone_identifier = [
    "subnet-0480420dfd34c4770",
    "subnet-086d579e9e69d29a5",
    "subnet-0b3bcfd70df2ede06"
  ]

  health_check_type         = "ELB"
  health_check_grace_period = 120

  launch_template {
    id      = aws_launch_template.lt-home.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.home-tg.arn]

  tag {
    key                 = "Name"
    value               = "home"
    propagate_at_launch = true
  }
}
