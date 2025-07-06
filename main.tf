#Create a VPC (Virtual Private Cloud):
#Define a new Terraform resource block for aws_vpc.
#Set the cidr_block attribute to "10.0.0.0/16" to specify the IP address range for the VPC.

 resource "aws_vpc" "devopschallenge_vpc" {
    cidr_block = "10.0.0.0/16"

    tags = {
      Name = "devopschallenge_vpc"
    }
  }

#Create a public subnet:
#Define a new Terraform resource block for aws_subnet.
#Set the vpc_id attribute to the ID of the VPC created in the previous step.
#Set the cidr_block attribute to "10.0.1.0/24" to specify the IP address range for the subnet.

resource "aws_subnet" "devopschallenge_public_subnet" {
    vpc_id     = aws_vpc.devopschallenge_vpc.id
    cidr_block = "10.0.1.0/24"

    tags = {
      Name = "devopschallenge_public_subnet"
    }
  }

#Create a private subnet:
#Define another Terraform resource block for aws_subnet.
#Set the vpc_id attribute to the ID of the VPC.
#Set the cidr_block attribute to "10.0.2.0/24" for the subnet IP address range.
  resource "aws_subnet" "devopschallenge_private_subnet" {
    vpc_id     = aws_vpc.devopschallenge_vpc.id
    cidr_block = "10.0.2.0/24"

    tags = {
      Name = "devopschallenge_private_subnet"
    }
  }
#Create an Internet Gateway (IGW):
#Define a Terraform resource block for aws_internet_gateway.
#Attach the Internet Gateway to the VPC by setting the vpc_id attribute.
 
 resource "aws_internet_gateway" "devopschallenge_igw" {
    vpc_id = aws_vpc.devopschallenge_vpc.id

    tags = {
      Name = "devopschallenge_igw"
    }
  }

  resource "aws_route" "igw_route" {
    route_table_id         = aws_route_table.devopschallenge_routetable.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id             = aws_internet_gateway.devopschallenge_igw.id
  }

#Create a route table for the public subnet
#Define a Terraform resource block for aws_route_table.
#Associate the route table with the public subnet by setting the vpc_id attribute.
#Add a route to the Internet Gateway using the aws_route resource block.
resource "aws_route_table" "devopschallenge_routetable" {
    vpc_id = aws_vpc.devopschallenge_vpc.id

    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.devopschallenge_igw.id
    }

    tags = {
      Name = "devopschallenge_routetable"
    }
  }

  resource "aws_route_table_association" "public_subnet_association" {
    subnet_id      = aws_subnet.devopschallenge_public_subnet.id
    route_table_id = aws_route_table.devopschallenge_routetable.id
  }

  resource "aws_route_table_association" "private_subnet_association" {
    subnet_id      = aws_subnet.devopschallenge_private_subnet.id
    route_table_id = aws_route_table.devopschallenge_routetable.id
  }

#Launch an EC2 instance in the public subnet:
#Define a Terraform resource block for aws_instance.
#Set the ami attribute to "ami-0eb260c4d5475b901" for the Amazon Machine Image (AMI).
#Set the instance_type attribute to "t2.micro" for the instance type.
#Specify a security group that allows SSH access from anywhere.
#Use the user_data attribute to provide a shell script that installs Apache and hosts a simple website.

resource "aws_security_group" "devopschallenge_sg" {
    name_prefix = "devopschallenge_sg"
    vpc_id      = aws_vpc.devopschallenge_vpc.id

    ingress {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }

  }

  resource "aws_instance" "devopschallenge_ec2instance" {
    ami           = "ami-0eb260c4d5475b901"
    instance_type = "t2.micro"
    key_name      = "devopschallenge-key"
    subnet_id     = aws_subnet.devopschallenge_public_subnet.id
    security_groups = [
      aws_security_group.devopschallenge_sg.id
    ]

    user_data = <<-EOF
                  #!/bin/bash
                  sudo apt update
                  sudo apt install -y apache2
                  sudo systemctl start apache2
                  sudo systemctl enable apache2
                  echo "<html><body><h1>Welcome to my website!</h1></body></html>" > /var/www/html/index.html
                  sudo systemctl restart apache2
                  EOF
    tags = {
      Name = "devopschallenge_ec2instance"
    }
  }

#Create an Elastic IP (EIP):
#Define a Terraform resource block for aws_eip.
#Associate the Elastic IP with the EC2 instance by setting the instance attribute to the ID of the instance.

 resource "aws_eip" "devopschallenge_eip" {
    instance = aws_instance.devopschallenge_ec2instance.id
  }

  
