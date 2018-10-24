

# HOST BUILD 1
hostname node1
systemctl stop firewalld ; systemctl disable firewalld
yum install -y wget
yum upgrade -y

# BUILD HWX REPOS
#wget http://public-repo-1.hortonworks.com/ambari/centos7/2.x/updates/2.6.2.2/ambari-2.6.2.2-centos7.tar.gz -P /opt/
#wget http://public-repo-1.hortonworks.com/HDP-UTILS-1.1.0.22/repos/centos6/HDP-UTILS-1.1.0.22-centos7.tar.gz -P /opt/
#wget http://public-repo-1.hortonworks.com/HDP/centos6/2.x/updates/2.6.5.0/HDP-2.6.5.0-centos7-rpm.tar.gz -P /opt/
mkdir /opt/www ; cat /opt/*.tar.gz | tar -zxf - -i -C /opt/www/
mkdir -p /opt/www/ambari/centos7/2.x/updates/2.6.2.2 ; mv /opt/www/ambari/centos7/2.6.2.2-1/* /opt/www/ambari/centos7/2.x/updates/2.6.2.2/
mkdir -p /opt/www/HDP-UTILS-1.1.0.22/repos/centos7 ; mv /opt/www/HDP-UTILS/centos7/1.1.0.22/* /opt/www/HDP-UTILS-1.1.0.22/repos/centos7/
mkdir -p /opt/www/HDP/centos7/2.x/updates/2.6.5.0 ; mv /opt/www/HDP/centos7/2.6.5.0-292/* /opt/www/HDP/centos7/2.x/updates/2.6.5.0/
rm -rf /opt/www/HDP-UTILS /opt/www/HDP/centos7/2.6.5.0-292 /opt/www/ambari/centos7/2.x/updates/2.6.2.2-1
find /opt/www/ -name "*.repo" -exec sed -i 's/public-repo-1.hortonworks.com/hdprepo/' {} \;
find /opt/www/ -name "*.repo" -exec sed -i 's/gpgcheck=1/gpgcheck=0/' {} \;

# HOST BUILD 2
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce net-tools git
systemctl enable docker.service
systemctl start docker
echo "StrictHostKeyChecking=no" >> /etc/ssh/ssh_config
ssh-keygen -t rsa -f /root/.ssh/id_rsa -N ''
cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys ; tar -cf keys.tar -C /root/ .ssh
printf '172.20.0.1      node1\n172.20.0.2      node2\n172.20.0.3      node3\n172.20.0.4      node4\n172.20.0.5      node5\n172.20.0.10      hdprepo' >> /etc/hosts
printf '*       soft    nofile  128000\n*       hard    nofile  128000' >> /etc/security/limits.d/20-nproc.conf
ulimit -n 128000
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sed -i 's/localhost/node1/' /etc/ambari-agent/conf/ambari-agent.ini"


# PDSH
wget http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
rpm -ivh epel-release-latest-7.noarch.rpm
yum install -y pdsh
echo "export PDSH_RCMD_TYPE='ssh'" >> ~/.bashrc
echo "export WCOLL='/etc/pdsh/machines'"  >> ~/.bashrc
mkdir /etc/pdsh
printf 'node1\nnode2\nnode3\nnode4\nnode5' >> /etc/pdsh/machines

# DOCKER HTTP INSTALL
docker network create --subnet=172.20.0.0/16 hadoop
docker run -dit --name hdprepo --net hadoop --ip 172.20.0.10 --hostname hdprepo -p 8080:80 -v /opt/www/:/usr/local/apache2/htdocs/ httpd:2.4
yum-config-manager --add-repo http://hdprepo/HDP/centos7/2.x/updates/2.6.5.0/hdp.repo
yum-config-manager --add-repo http://hdprepo/ambari/centos7/2.x/updates/2.6.2.2/ambari.repo

# DOCKER NODES
cp /etc/yum.repos.d/ambari.repo ./ ; cp /etc/yum.repos.d/hdp.repo ./
docker build --rm -t jpcloud/ssh:centos_hadoop .
docker run -d --name node2 --net hadoop --ip 172.20.0.2 --hostname node2 --add-host node1:172.20.0.1 --add-host node3:172.20.0.3 --add-host node4:172.20.0.4 --add-host node5:172.20.0.5 --add-host hdprepo:172.20.0.10 -it --cap-add SYS_ADMIN --privileged jpcloud/ssh:centos_hadoop
docker run -d --name node3 --net hadoop --ip 172.20.0.3 --hostname node3 --add-host node1:172.20.0.1 --add-host node2:172.20.0.2 --add-host node4:172.20.0.4 --add-host node5:172.20.0.5 --add-host hdprepo:172.20.0.10 -it --cap-add SYS_ADMIN --privileged jpcloud/ssh:centos_hadoop
docker run -d --name node4 --net hadoop --ip 172.20.0.4 --hostname node4 --add-host node1:172.20.0.1 --add-host node2:172.20.0.2 --add-host node3:172.20.0.3 --add-host node5:172.20.0.5 --add-host hdprepo:172.20.0.10 -it --cap-add SYS_ADMIN --privileged jpcloud/ssh:centos_hadoop
docker run -d --name node5 --net hadoop --ip 172.20.0.5 --hostname node5 --add-host node1:172.20.0.1 --add-host node2:172.20.0.2 --add-host node3:172.20.0.3 --add-host node4:172.20.0.4 --add-host hdprepo:172.20.0.10 -it --cap-add SYS_ADMIN --privileged jpcloud/ssh:centos_hadoop

## HADOOP INSTALLATION
yum install -y ambari-server
ambari-server setup -s
ambari-server setup --jdbc-db=mysql --jdbc-driver=/root/HDP26DOCKER/mysql-connector-java.jar
ambari-server start

. ~/.bashrc
pdsh 'wget http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm'
pdsh 'rpm -ivh epel-release-latest-7.noarch.rpm'
pdsh 'yum install -y pdsh'
pdcp /etc/yum.repos.d/ambari.repo /etc/yum.repos.d
pdsh 'yum clean all'
pdsh 'yum install -y ambari-agent'
pdsh "sed -i 's/localhost/node1/' /etc/ambari-agent/conf/ambari-agent.ini"
pdsh "sed -i '/credential_shell_cmd/a force_https_protocol=PROTOCOL_TLSv1_2' /etc/ambari-agent/conf/ambari-agent.ini"
pdsh ambari-agent restart
