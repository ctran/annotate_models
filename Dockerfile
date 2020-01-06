##
# Usage:
#
#   # build the image
#   docker build -t annotate-docker .
#
#   # run a bash login shell in a container running that image
#   docker run -it annotate-docker bash -l
#
# References:
# https://github.com/ms-ati/docker-rvm/blob/master/Dockerfile
# https://hub.docker.com/r/instructure/rvm/dockerfile
##

FROM ubuntu:18.04

ARG RVM_USER=docker

# RVM version to install
ARG RVM_VERSION=stable

# Directorry path
ARG PROJECT_PATH=/annotate_models

# Install RVM
RUN apt-get update \
    && apt-get install -y \
       curl \
       git \
       gnupg2 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/

RUN addgroup --gid 9999 ${RVM_USER} \
 && adduser --uid 9999 --gid 9999 --disabled-password --gecos "Docker User" ${RVM_USER} \
 && usermod -L ${RVM_USER}

# No ipv6 support in container (https://github.com/inversepath/usbarmory-debian-base_image/issues/)
RUN mkdir ~/.gnupg && echo "disable-ipv6" >> ~/.gnupg/dirmngr.conf

# https://superuser.com/questions/954509/what-are-the-correct-permissions-for-the-gnupg-enclosing-folder-gpg-warning
RUN chmod 700 ~/.gnupg && chmod 600 ~/.gnupg/*

# Install + verify RVM with gpg (https://rvm.io/rvm/security)
RUN gpg2 --quiet --no-tty --logger-fd 1 --keyserver hkp://keys.gnupg.net \
         --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 \
                     7D2BAF1CF37B13E2069D6956105BD0E739499BDB \
    && echo 409B6B1796C275462A1703113804BB82D39DC0E3:6: | \
       gpg2 --quiet --no-tty --logger-fd 1 --import-ownertrust \
    && curl -sSO https://raw.githubusercontent.com/rvm/rvm/${RVM_VERSION}/binscripts/rvm-installer \
    && curl -sSO https://raw.githubusercontent.com/rvm/rvm/${RVM_VERSION}/binscripts/rvm-installer.asc \
    && gpg2 --quiet --no-tty --logger-fd 1 --verify rvm-installer.asc \
    && bash rvm-installer ${RVM_VERSION} \
    && rm rvm-installer rvm-installer.asc \
    && echo "bundler" >> /usr/local/rvm/gemsets/global.gems \
    && echo "rvm_silence_path_mismatch_check_flag=1" >> /etc/rvmrc \
    && echo "install: --no-document" > /etc/gemrc

# Workaround tty check, see https://github.com/hashicorp/vagrant/issues/1673#issuecomment-26650102
RUN sed -i 's/^mesg n/tty -s \&\& mesg n/g' /root/.profile

# Switch to a bash login shell to allow simple 'rvm' in RUN commands
SHELL ["/bin/bash", "-l", "-c"]
RUN rvm group add rvm "${RVM_USER}"

# Create project directory and copy path
RUN mkdir -p /${PROJECT_PATH} && chown ${RVM_USER}:${RVM_USER} /${PROJECT_PATH}
COPY . /${PROJECT_PATH}

# Switch to user
USER ${RVM_USER}
RUN echo ". /etc/profile.d/rvm.sh" >> ~/.bashrc

WORKDIR ${PROJECT_PATH}
