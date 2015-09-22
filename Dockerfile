FROM ubuntu:14.04
# Bro 2.4.1 
MAINTAINER Daniel Guerra <daniel.guerra69@gmail.com>

#prequisits
RUN apt-get update && DEBIAN_FRONTEND=noninteractive
RUN apt-get -y upgrade && DEBIAN_FRONTEND=noninteractive
RUN apt-get -y  install build-essential devscripts sendmail  libffi-dev libclick-0.4-dev Ocl-icd-opencl-dev libboost-dev doxygen git libcurl4-gnutls-dev libgoogle-perftools-dev libgeoip-dev geoip-database rsync openssh-server pwgen cmake make gcc g++ flex bison libpcap-dev libssl-dev python-dev swig zlib1g-dev php5-curl openssl gawk libgflags-dev libsnappy-dev libbz2-dev


#prequisits from source
#rocksdb
WORKDIR /tmp
RUN git clone --recursive https://github.com/facebook/rocksdb.git
WORKDIR /tmp/rocksdb
RUN export CFLAGS="$CFLAGS -fPIC"
RUN export CXXFLAGS="$CXXFLAGS -fPIC"
RUN make static_lib
RUN make install

# ipsumdump
WORKDIR /tmp
RUN git clone --recursive https://github.com/kohler/ipsumdump.git
WORKDIR /tmp/ipsumdump
RUN ./configure
RUN make
RUN make install

#actor framework caf to enable broker
WORKDIR /tmp
RUN git clone --recursive --branch 0.14.1 https://github.com/actor-framework/actor-framework.git
WORKDIR /tmp/actor-framework
# RUN git submodule foreach git checkout master
# RUN git submodule foreach git pull
# RUN ./configure --no-riac
RUN ./configure --no-examples --no-benchmarks --no-opencl
RUN make
RUN make install

#bro 2.4.1
WORKDIR /tmp
RUN git clone --recursive git://git.bro.org/bro
RUN WORKDIR /tmp/bro
RUN ./configure
RUN make all
RUN make install
WORKDIR /tmp/bro/aux/plugins/elasticsearch
RUN ./configure
RUN make
RUN make install

#clean the dev packages 
RUN apt-get -y remove libffi-dev libclick-0.4-dev ocl-icd-opencl-dev libboost-dev libcurl4-gnutls-dev libgeoip-dev cmake make gcc g++ flex bison libssl-dev python-dev swig zlib1g-dev curl bzip2 snappy
RUN apt-get -y autoremove

#cleanup apt & build action
WORKDIR /tmp
RUN rm -rf *

WORKDIR /var/cache/apt
RUN rm -rf *

WORKDIR /var/log
RUN rm -rf *

#set sshd config for key based authentication
RUN mkdir -p /var/run/sshd && sed -i "s/UsePrivilegeSeparation.*/UsePrivilegeSeparation no/g" /etc/ssh/sshd_config && sed -i "s/UsePAM.*/UsePAM no/g" /etc/ssh/sshd_config && sed -i "s/PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config && sed -i "s/#AuthorizedKeysFile/AuthorizedKeysFile/g" /etc/ssh/sshd_config

EXPOSE 22
EXPOSE 47761
EXPOSE 47762

#start sshd
CMD [exec,/usr/sbin/sshd,-D]
