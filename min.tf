provider "aws" {
    region = "ap-southeast-2"
}
resource "aws_instance" "Kartik" {
    ami = "ami-0ba8d27d35e9915fb"
    instance_type = "t3.micro"
    vpc_security_group_ids = "sg-08e94ae8ffb34b5d5"

    tags = {
        Name = "Kartik"
    }
}
