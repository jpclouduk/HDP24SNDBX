# 

FROM centos:centos7
MAINTAINER jpcloud

RUN yum -y update; yum clean all
RUN yum -y install openssh-server passwd tar; yum clean all
RUN sed -i 's/prohibit-password/yes/' /etc/ssh/sshd_config
RUN echo "StrictHostKeyChecking=no" >> /etc/ssh/ssh_config
ADD ./keys.tar /root
ADD /etc/yum.repos.d/ambari.repo /etc/yum.repos.d/
ADD /etc/yum.repos.d/hdp.repo /etc/yum.repos.d/
RUN mkdir /var/run/sshd

RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N '' 

ENTRYPOINT ["/usr/sbin/sshd", "-D"]
