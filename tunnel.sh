#!/bin/bash

    ssh -i private/initial/aws/docker.pem -L 127.0.0.1:8080:127.0.0.1:8080 -o UseStrictHostKeyChecking=no -N -l fedora $(vagrant ssh initial -- curl http://instance-data/latest/meta-data/public-ipv4) &&
    true
