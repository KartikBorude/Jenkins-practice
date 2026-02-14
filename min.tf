provider "aws" {
    region = "ap-southeast-2"
}
resource "aws_lb_target_group" "home-tg" {
    name        = "home-tg"
    target_type = "instance"
    port        = 80
    protocol    = "HTTP"
    vpc_id      = "vpc-000dab9b0ef9d0ac3"

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

resource "aws_lb" "alb" {
    name               = "alb"
    internal           = false
    load_balancer_type = "application"
    security_groups    = ["sg-08e94ae8ffb34b5d5"]
    subnets = [
        "subnet-0b05efd84e53889ba",
        "subnet-039fcf23f9a08c2b5",
        "subnet-076186745713f7362",
    ]
    }

resource "aws_lb_listener" "alb-listener" {
    load_balancer_arn = aws_lb.alb.arn
    port              = 80
    protocol          = "HTTP"

    default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.home-tg.arn
        }
    }

resource "aws_autoscaling_group" "asg-home" {
    name                      = "asg-home"
    availability_zones        = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
    desired_capacity          = 1
    max_size                  = 1
    min_size                  = 1
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
