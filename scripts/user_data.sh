#!/bin/bash -xe
yum update -y
amazon-linux-extras enable php7.4
yum install -y httpd php php-mysqlnd mariadb unzip wget

systemctl enable httpd
systemctl start httpd

systemctl enable mariadb
systemctl start mariadb

until mysqladmin ping --silent; do
  echo "Waiting for MySQL to start..."
  sleep 2
done

mysql -e "CREATE DATABASE wp_landing_db DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;"
mysql -e "CREATE USER 'wp_ricardo'@'localhost' IDENTIFIED BY 'W0rdPr3ssRic2024!';"
mysql -e "GRANT ALL PRIVILEGES ON wp_landing_db.* TO 'wp_ricardo'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

cd /var/www/html
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
cp -r wordpress/* .
rm -rf wordpress latest.tar.gz

cp wp-config-sample.php wp-config.php
sed -i "s/database_name_here/wp_landing_db/" wp-config.php
sed -i "s/username_here/wp_ricardo/" wp-config.php
sed -i "s/password_here/W0rdPr3ssRic2024!/" wp-config.php
sed -i "s/localhost/localhost/" wp-config.php

chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html

yum install -y amazon-cloudwatch-agent
cat > /opt/aws/amazon-cloudwatch-agent/bin/config.json << CONFIG
{
  "metrics": {
    "metrics_collected": {
      "mem": {
        "measurement": ["mem_used_percent"]
      },
      "disk": {
        "measurement": ["used_percent"],
        "resources": ["*"]
      }
    },
    "append_dimensions": {
      "InstanceId": "$${aws:InstanceId}"
    }
  }
}
CONFIG

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json -s
