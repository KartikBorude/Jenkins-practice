provider "aws" {
    region = "ap-southeast-2"
}
resource "aws_instance" "linux" {
    ami = "ami-0ba8d27d35e9915fb"
    instance_type = "c7i-flex.large"
    

    tags = {
        Name = "linux"
    }
}
