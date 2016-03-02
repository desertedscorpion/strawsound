#!/bin/bash

PORT=29042 &&
    ENVIRONMENT=testing &&
    (cat <<EOF
Test the docker provisioning script.
EOF
    ) &&
    function test_docker ()
{
    vagrant ssh testing -- which docker &&
	vagrant ssh testing -- if [ -d /home/fedora/docker ] ; then exit 64; fi &&
	true
} &&
    (
	vagrant destroy --force testing ||
	    echo "I really do not know why this fails from time to time, but as long as the instance is destroyed it is OK"
    ) &&
    time vagrant up testing --provider=aws &&
    test_docker &&
    true
