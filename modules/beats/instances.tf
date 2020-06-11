resource "aws_instance" "radius" {
  ami           = "ami-032598fcc7e9d1c7a"
  instance_type = "t2.medium"
  subnet_id     = var.subnet_ids[1]

  vpc_security_group_ids = [
    "${aws_security_group.pttp-logging-spike.id}"
  ]
  key_name               = aws_key_pair.bastion_public_key_pair.key_name
  associate_public_ip_address = true
  iam_instance_profile = "${aws_iam_instance_profile.beats-instance-profile.id}"
  monitoring           = true

  user_data = <<DATA
Content-Type: multipart/mixed; boundary="==BOUNDARY=="
MIME-Version: 1.0

--==BOUNDARY==
MIME-Version: 1.0
Content-Type: text/cloud-config; charset="us-ascii"
#cloud-config
repo_update: true
repo_upgrade: all

--==BOUNDARY==
MIME-Version: 1.0
Content-Type: text/x-shellscript; charset="us-ascii"
#!/bin/bash
sudo yum install perl-Switch perl-DateTime perl-Sys-Syslog perl-LWP-Protocol-https -y
sudo yum -y install perl-Digest-SHA perl-URI perl-libwww-perl perl-MIME-tools perl-Crypt-SSLeay perl-XML-LibXML unzip curl
mkdir -p /home/ec2-user/scripts
cd /home/ec2-user/scripts
curl https://aws-cloudwatch.s3.amazonaws.com/downloads/CloudWatchMonitoringScripts-1.2.2.zip -O
unzip CloudWatchMonitoringScripts-1.2.2.zip
rm CloudWatchMonitoringScripts-1.2.2.zip
mv aws-scripts-mon /home/ec2-user/scripts/mon

touch /var/log/dummy-log
chmod 777 /var/log/dummy-log

while true; do echo "Hello from the Prison Technology Transformation Programme" >> /var/log/dummy-log; sleep 1; done &
echo "done" >> ~/whatever

EOF

--==BOUNDARY==
MIME-Version: 1.0
Content-Type: text/x-shellscript; charset="us-ascii"
#!/bin/bash
# Install awslogs and the jq JSON parser
yum install -y awslogs jq

# Inject the CloudWatch Logs configuration file contents
cat > /etc/awslogs/awslogs.conf <<- EOF
[general]
state_file = /var/lib/awslogs/agent-state

[/var/log/dummy-log]
file = /var/log/dummy-log
log_group_name = /var/log/dummy-log
log_stream_name = {instance_id}/{hostname}
datetime_format = %b %d %H:%M:%S
EOF

echo "done cloudwatch log config" >> ~/whatever

--==BOUNDARY==
MIME-Version: 1.0
Content-Type: text/x-shellscript; charset="us-ascii"
#!/bin/bash
region=eu-west-2
sed -i -e "s/region = us-east-1/region = $region/g" /etc/awslogs/awscli.conf
systemctl start awslogsd
systemctl enable awslogsd.service

echo "done script and done" >> ~/whatever

--==BOUNDARY==
DATA

  tags = {
    Name = "PTTP"
    Env  = "test"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "tls_private_key" "ec2" {
  algorithm = "RSA"
}

resource "aws_key_pair" "bastion_public_key_pair" {
  key_name   = "pttp-test"
  public_key = tls_private_key.ec2.public_key_openssh
}

resource "aws_ssm_parameter" "instance_private_key" {
  name        = "/ec2/master"
  type        = "SecureString"
  value       = tls_private_key.ec2.private_key_pem
  overwrite   = true
  description = "master ssh key for env"
}
