FROM centos:centos6
# Install dependencies
RUN yum update --assumeyes
RUN yum install --assumeyes epel-release
RUN yum install --assumeyes nodejs npm
# Install app
COPY src/package.json /src/package.json
RUN cd /src; npm install
COPY src/server.express.js /src
RUN rm -rf /var/www/*
ADD src /var/www
EXPOSE 3000
CMD ["node" "/src/server.express.js"]