#!/bin/bash

source /usr/local/src/private/credentials.sh &&
    ssh -i docker.pem -L 127.0.0.1:8080:127.0.0.1:8080 -o StrictHostKeyChecking=no -N -l fedora $(vagrant ssh initial -- curl http://instance-data/latest/meta-data/public-ipv4) &&
    true
