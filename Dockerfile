# 

FROM centos:centos7
MAINTAINER jpcloud

# Section to enable systemd
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == \
systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;
VOLUME [ "/sys/fs/cgroup" ]

RUN yum -y update; yum clean all; \
yum -y install openssh-server openssh-clients passwd tar wget; \
yum clean all ; systemctl enable sshd.service ; \
sed -i 's/prohibit-password/yes/' /etc/ssh/sshd_config ; \
echo "StrictHostKeyChecking=no" >> /etc/ssh/ssh_config ; \
sed -i 's/tsflags/#tsflags/' /etc/yum.conf ; \
mkdir /var/run/sshd ; \
rm /var/run/nologin
ADD ./keys.tar /root
ADD *.repo /etc/yum.repos.d/

CMD ["/usr/sbin/init"]
