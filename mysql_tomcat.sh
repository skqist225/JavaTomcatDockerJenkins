#!/bin/bash
DATABASE_PASS='123456'
sudo yum update -y
sudo yum install epel-release -y
sudo yum install git zip unzip -y
sudo yum install mariadb-server -y
sudo yum install java-1.8.0-openjdk -y
sudo yum install java-1.8.0-openjdk-devel -y
sudo yum install wget -y
sudo yum install nano -y

# starting & enabling mariadb-server
sudo systemctl start mariadb
sudo systemctl enable mariadb
cd /tmp/
git clone https://github.com/skqist225/AirTNT2.git
#restore the dump file for the application
sudo mysqladmin -u root password "$DATABASE_PASS"
sudo mysql -u root -p"$DATABASE_PASS" -e "UPDATE mysql.user SET Password=PASSWORD('$DATABASE_PASS') WHERE User='root'"
sudo mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
sudo mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.user WHERE User=''"
sudo mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%'"
sudo mysql -u root -p"$DATABASE_PASS" -e "FLUSH PRIVILEGES"
sudo mysql -u root -p"$DATABASE_PASS" -e "create database airtnt"
sudo mysql -u root -p"$DATABASE_PASS" -e "grant all privileges on airtnt.* TO 'root'@'localhost' identified by '123456'"
sudo mysql -u root -p"$DATABASE_PASS" -e "grant all privileges on airtnt.* TO 'root'@'%' identified by '123456'"
sudo mysql -u root -p"$DATABASE_PASS" airtnt < /tmp/AirTNT2/AirTNT/airtnt.sql
sudo mysql -u root -p"$DATABASE_PASS" -e "FLUSH PRIVILEGES"

# Restart mariadb-server
sudo systemctl restart mariadb

#starting the firewall and allowing the mariadb to access from port no. 3306
sudo systemctl start firewalld
sudo systemctl enable firewalld
sudo firewall-cmd --get-active-zones
sudo firewall-cmd --zone=public --add-port=3306/tcp --permanent
sudo firewall-cmd --reload
sudo systemctl restart mariadb


# TOMCAT 
sudo useradd --shell /sbin/nologin tomcat
cd /tmp/
wget https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.56/bin/apache-tomcat-9.0.56.tar.gz

sudo mkdir /opt/tomcat/
sudo tar -xf /tmp/apache-tomcat-9.0.56.tar.gz -C /opt/tomcat/
sudo chmod +x /opt/tomcat/apache-tomcat-9.0.56/bin/*.sh
sudo ln -s /opt/tomcat/apache-tomcat-9.0.56 /opt/tomcat/latest
sudo chown -R tomcat: /opt/tomcat

sudo rm -rf /etc/systemd/system/tomcat.service
sudo -i
sudo cat <<EOT>> /etc/systemd/system/tomcat.service
[Unit]
Description=Tomcat 9 servlet container
After=network.target

[Service]
Type=forking

User=tomcat
Group=tomcat

Environment=JAVA_HOME=/usr/lib/jvm/jre
Environment=JAVA_OPTS=-Djava.security.egd=file:///dev/urandom

Environment=CATALINA_BASE=/opt/tomcat/latest
Environment=CATALINA_HOME=/opt/tomcat/latest
Environment=CATALINA_PID=/opt/tomcat/latest/temp/tomcat.pid
Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"

ExecStart=/opt/tomcat/latest/bin/startup.sh
ExecStop=/opt/tomcat/latest/bin/shutdown.sh

[Install]
WantedBy=multi-user.target
EOT
exit

sudo systemctl daemon-reload
sudo systemctl start tomcat
sudo systemctl enable tomcat
sudo firewall-cmd --zone=public --permanent --add-port=8080/tcp
sudo firewall-cmd --reload

#MAVEN
wget https://downloads.apache.org/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz -P /tmp
sudo tar xf /tmp/apache-maven-3.6.3-bin.tar.gz -C /opt
sudo ln -s /opt/apache-maven-3.6.3 /opt/maven

export JAVA_HOME=/usr/lib/jvm/jre-openjdk
export M2_HOME=/opt/maven
export MAVEN_HOME=/opt/maven
export PATH=${M2_HOME}/bin:${PATH} 
export MAVEN_OPTS="-Xmx512m"

cd /tmp/AirTNT2/AirTNT/target/
rm AirTNT-0.0.1-SNAPSHOT.war -y
systemctl stop tomcat
sleep 10
rm -rf /opt/tomcat/latest/webapps/ROOT*
cp /tmp/AirTNT2/AirTNT/target/AirTNT-0.0.1-SNAPSHOT.war /opt/tomcat/latest/webapps/ROOT.war
#aws s3 cp s3://airtnt/AirTNT-0.0.1-SNAPSHOT.war /opt/tomcat/latest/webapps/ROOT.war
#db enpoint: airtnt-mysql-db.c571muvkfnd1.us-east-2.rds.amazonaws.com
systemctl start tomcat
sleep 10
cp /tmp/AirTNT2/AirTNT/src/main/resources/application.properties /opt/tomcat/latest/webapps/ROOT/WEB-INF/classes/application.properties
systemctl restart tomcat

systemctl stop tomcat
sleep 10
rm -rf /opt/tomcat/latest/webapps/ROOT*
aws s3 cp s3://airtnt/AirTNT-0.0.1-SNAPSHOT.war /opt/tomcat/latest/webapps/ROOT.war
systemctl start tomcat
sleep 10
cp /tmp/AirTNT2/AirTNT/src/main/resources/application.properties /opt/tomcat/latest/webapps/ROOT/WEB-INF/classes/application.properties