


# HOST SECTION
systemctl stop firewalld ; systemctl disable firewalld
yum upgrade -y
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum-config-manager --add-repo http://public-repo-1.hortonworks.com/HDP/centos7/2.x/updates/2.6.5.0/hdp.repo
yum-config-manager --add-repo http://public-repo-1.hortonworks.com/ambari/centos7/2.x/updates/2.6.2.2/ambari.repo
yum-config-manager --enable docker-ce-edge HDP-2.6.5.0 HDP-UTILS-1.1.0.22 ambari-2.6.2.2
yum install -y docker-ce net-tools wget git
systemctl start docker
echo "StrictHostKeyChecking=no" >> /etc/ssh/ssh_config
ssh-keygen -t rsa
cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys ; tar -cf keys.tar -C /root/ .ssh




# DOCKER SECTION

docker build --rm -t jpcloud/ssh:centos_hadoop .

docker run -d --name node2 --net hadoop --ip 172.20.0.2 --hostname node2 --add-host node1:172.20.0.1 --add-host node3:172.20.0.3 --add-host node4:172.20.0.4 --add-host node5:172.20.0.5 -it jpcloud/ssh:centos_hadoop

docker run -d --name node3 --net hadoop --ip 172.20.0.3 --hostname node3 --add-host node1:172.20.0.1 --add-host node2:172.20.0.2 --add-host node4:172.20.0.4 --add-host node5:172.20.0.5 -it jpcloud/ssh:centos_hadoop

docker run -d --name node4 --net hadoop --ip 172.20.0.4 --hostname node4 --add-host node1:172.20.0.1 --add-host node2:172.20.0.2 --add-host node3:172.20.0.3 --add-host node5:172.20.0.5 -it jpcloud/ssh:centos_hadoop

docker run -d --name node5 --net hadoop --ip 172.20.0.5 --hostname node5 --add-host node1:172.20.0.1 --add-host node2:172.20.0.2 --add-host node3:172.20.0.3 --add-host node4:172.20.0.4 -it jpcloud/ssh:centos_hadoop
