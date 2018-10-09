


# HOST SECTION
systemctl stop firewalld ; systemctl disable firewalld
yum upgrade -y
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum-config-manager --add-repo http://public-repo-1.hortonworks.com/HDP/centos7/2.x/updates/2.6.5.0/hdp.repo
yum-config-manager --add-repo http://public-repo-1.hortonworks.com/ambari/centos7/2.x/updates/2.6.2.2/ambari.repo
yum-config-manager --enable docker-ce-edge HDP-2.6.5.0 HDP-UTILS-1.1.0.22 ambari-2.6.2.2
yum install -y docker-ce net-tools wget git
systemctl enable docker.service
systemctl start docker
echo "StrictHostKeyChecking=no" >> /etc/ssh/ssh_config
ssh-keygen -t rsa -f /root/.ssh/id_rsa -N ''
cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys ; tar -cf keys.tar -C /root/ .ssh
printf '172.20.0.1      node1\n172.20.0.2      node2\n172.20.0.3      node3\n172.20.0.4      node4\n172.20.0.5      node5' >> /etc/hosts
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf

# PDSH
wget http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
rpm -ivh epel-release-latest-7.noarch.rpm
yum install -y pdsh
echo "export PDSH_RCMD_TYPE='ssh'" >> ~/.bashrc
echo "export WCOLL='/etc/pdsh/machines'"  >> ~/.bashrc
mkdir /etc/pdsh
printf 'node1\nnode2\nnode3\nnode4\nnode5' >> /etc/pdsh/machines


# DOCKER BUILD OUT
cp /etc/yum.repos.d/ambari.repo ./ ; cp /etc/yum.repos.d/hdp.repo ./
docker network create --subnet=172.20.0.0/16 hadoop
docker build --rm -t jpcloud/ssh:centos_hadoop .
docker run -d --name node2 --net hadoop --ip 172.20.0.2 --hostname node2 --add-host node1:172.20.0.1 --add-host node3:172.20.0.3 --add-host node4:172.20.0.4 --add-host node5:172.20.0.5 -it --cap-add SYS_ADMIN jpcloud/ssh:centos_hadoop
docker run -d --name node3 --net hadoop --ip 172.20.0.3 --hostname node3 --add-host node1:172.20.0.1 --add-host node2:172.20.0.2 --add-host node4:172.20.0.4 --add-host node5:172.20.0.5 -it --cap-add SYS_ADMIN jpcloud/ssh:centos_hadoop
docker run -d --name node4 --net hadoop --ip 172.20.0.4 --hostname node4 --add-host node1:172.20.0.1 --add-host node2:172.20.0.2 --add-host node3:172.20.0.3 --add-host node5:172.20.0.5 -it --cap-add SYS_ADMIN jpcloud/ssh:centos_hadoop
docker run -d --name node5 --net hadoop --ip 172.20.0.5 --hostname node5 --add-host node1:172.20.0.1 --add-host node2:172.20.0.2 --add-host node3:172.20.0.3 --add-host node4:172.20.0.4 -it --cap-add SYS_ADMIN jpcloud/ssh:centos_hadoop

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
