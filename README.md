# HDP26DOCKER
Centos VM Build with 4x docker nodes
Use to run HDP build

1. Build your local virtualbox VM with CentOS-7-x86_64-Minimal-1804.
2. clone this project
  yum install git
  git clone https://github.com/jpclouduk/HDP26DOCKER.git
  cd HDP26DOCKER
  
You have 2 choices at this point.
  a. Install your cluster but point each node at the hortonworks repositories
     NOTE: this may take a long time to build as all nodes will pull at the same time
  b. Install your cluster with a local repo
     NOTE: the repo will be pulled in and installed but this will make the overall install faster
