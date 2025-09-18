provider "aws" {
  region = var.aws_region
}
 
# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "Backstage-VPC"  
    }
}
 
# Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true
}
 
# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}
 
# Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
 
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}
 
# Associate Route Table with Subnet
resource "aws_route_table_association" "public_rt_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}
 
# Security Group
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg"
  description = "Allow SSH, HTTP, and Monitoring traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Prometheus"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Blackbox Exporter"
    from_port   = 9115
    to_port     = 9115
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
 
# EC2 Instance
resource "aws_instance" "example" {
  ami                    = "ami-01b6d88af12965bb6"
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y

              #!/bin/bash
              # Update system
              yum update -y

              # Install Node.js (LTS) and Git
              curl -sL https://rpm.nodesource.com/setup_lts.x | bash -
              yum install -y nodejs git

              # Install PM2 to keep Node.js app running
              npm install -g pm2

              # Clone your Node.js app repo
              cd /home/ec2-user
              git clone https://github.com/Purvash-143/insurance-admin.git app
              cd app
              chown -R ec2-user:ec2-user /home/ec2-user/app
              
              npm install
              npm run build
              
              npm start
              # Deploy build output to Nginx web root
              # rm -rf /usr/share/nginx/html/*
              # cp -r build/* /usr/share/nginx/html/

              # # Enable & start Nginx
              # systemctl enable nginx
              # systemctl restart nginx
              # Install dependencies
              # npm install
              # # Set HOST to 0.0.0.0 and start React dev server with PM2
              # HOST=0.0.0.0 pm2 start npm --name insurance-dev -- start
              
              # # Optional: make PM2 auto-start on reboot
              # pm2 startup
              # pm2 save
              # sudo -u ec2-user pm2 start "npm run start" --name nodeapp
              # sudo -u ec2-user pm2 startup systemd -u ec2-user --hp /home/ec2-user
              # sudo -u ec2-user pm2 save
              # npm run dev

              # Start the app with PM2
              # pm2 start server.js --name nodeapp
              # pm2 startup systemd -u ec2-user --hp /home/ec2-user
              # pm2 save
              

              # Install Prometheus
              cd /opt
              wget https://github.com/prometheus/prometheus/releases/download/v2.45.0/prometheus-2.45.0.linux-amd64.tar.gz
              tar xvfz prometheus-2.45.0.linux-amd64.tar.gz
              mv prometheus-2.45.0.linux-amd64 prometheus
              chown -R ec2-user:ec2-user /opt/prometheus

              # Install Blackbox Exporter for HTTP health checks
              cd /opt
              wget https://github.com/prometheus/blackbox_exporter/releases/download/v0.24.0/blackbox_exporter-0.24.0.linux-amd64.tar.gz
              tar xvfz blackbox_exporter-0.24.0.linux-amd64.tar.gz
              mv blackbox_exporter-0.24.0.linux-amd64 blackbox_exporter
              chown -R ec2-user:ec2-user /opt/blackbox_exporter

              # Create Prometheus configuration
              cat > /opt/prometheus/prometheus.yml << 'PROM_CONFIG'
              global:
                scrape_interval: 15s

              scrape_configs:
                - job_name: 'prometheus'
                  static_configs:
                    - targets: ['localhost:9090']

                - job_name: 'blackbox'
                  static_configs:
                    - targets: ['localhost:9115']

                - job_name: 'java-app-health'
                  metrics_path: /probe
                  params:
                    module: [http_2xx]
                  static_configs:
                    - targets:
                      - http://localhost:3000
                  relabel_configs:
                    - source_labels: [__address__]
                      target_label: __param_target
                    - source_labels: [__param_target]
                      target_label: instance
                    - target_label: __address__
                      replacement: localhost:9115
              PROM_CONFIG

              # Create Blackbox Exporter configuration
              cat > /opt/blackbox_exporter/blackbox.yml << 'BLACKBOX_CONFIG'
              modules:
                http_2xx:
                  prober: http
                  timeout: 5s
                  http:
                    valid_http_versions: ["HTTP/1.1", "HTTP/2.0"]
                    valid_status_codes: []  # Defaults to 2xx
                    method: GET
                    follow_redirects: true
                    fail_if_ssl: false
                    fail_if_not_ssl: false
              BLACKBOX_CONFIG

              # Create systemd service for Prometheus
              cat > /etc/systemd/system/prometheus.service << 'PROM_SERVICE'
              [Unit]
              Description=Prometheus
              Wants=network-online.target
              After=network-online.target

              [Service]
              User=ec2-user
              Group=ec2-user
              Type=simple
              ExecStart=/opt/prometheus/prometheus --config.file=/opt/prometheus/prometheus.yml --storage.tsdb.path=/opt/prometheus/data --web.console.templates=/opt/prometheus/consoles --web.console.libraries=/opt/prometheus/console_libraries

              [Install]
              WantedBy=multi-user.target
              PROM_SERVICE

              # Create systemd service for Blackbox Exporter
              cat > /etc/systemd/system/blackbox_exporter.service << 'BLACKBOX_SERVICE'
              [Unit]
              Description=Blackbox Exporter
              Wants=network-online.target
              After=network-online.target

              [Service]
              User=ec2-user
              Group=ec2-user
              Type=simple
              ExecStart=/opt/blackbox_exporter/blackbox_exporter --config.file=/opt/blackbox_exporter/blackbox.yml

              [Install]
              WantedBy=multi-user.target
              BLACKBOX_SERVICE

              # Start services
              systemctl daemon-reload
              systemctl enable prometheus
              systemctl start prometheus
              systemctl enable blackbox_exporter
              systemctl start blackbox_exporter
              EOF
 
  tags = {
    Name = var.instance_name
  }
}

# Output the public IP address
output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.example.public_ip
}

# Output the application URL
output "application_url" {
  description = "URL to access the Java web application"
  value       = "http://${aws_instance.example.public_ip}:3000"
}

# Output the Prometheus URL
output "prometheus_url" {
  description = "URL to access Prometheus monitoring"
  value       = "http://${aws_instance.example.public_ip}:9090"
}

# Output the Blackbox Exporter URL
output "blackbox_exporter_url" {
  description = "URL to access Blackbox Exporter for health checks"
  value       = "http://${aws_instance.example.public_ip}:9115"
}