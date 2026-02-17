provider "aws" {
  region = "ap-southeast-2"
}

# 1️⃣ VPC
resource "aws_vpc" "kartik_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "kartik-vpc"
  }
}

# 2️⃣ Subnet
resource "aws_subnet" "kartik_subnet" {
  vpc_id                  = aws_vpc.kartik_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "kartik-subnet"
  }
}

# 3️⃣ Internet Gateway
resource "aws_internet_gateway" "kartik_igw" {
  vpc_id = aws_vpc.kartik_vpc.id

  tags = {
    Name = "kartik-igw"
  }
}

# 4️⃣ Route Table
resource "aws_route_table" "kartik_rt" {
  vpc_id = aws_vpc.kartik_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.kartik_igw.id
  }

  tags = {
    Name = "kartik-rt"
  }
}

# 5️⃣ Associate Route Table with Subnet
resource "aws_route_table_association" "kartik_rta" {
  subnet_id      = aws_subnet.kartik_subnet.id
  route_table_id = aws_route_table.kartik_rt.id
}

# 6️⃣ Security Group
resource "aws_security_group" "kartik_sg" {
  vpc_id = aws_vpc.kartik_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "kartik-sg"
  }
}

# 7️⃣ EC2 Instance
resource "aws_instance" "kartik_instance" {
  ami                         = "ami-0ba8d27d35e9915fb"
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.kartik_subnet.id
  vpc_security_group_ids      = [aws_security_group.kartik_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "Kartik-Instance"
  }
}
