#!/bin/bash

echo Test the docker provisioning script. &&
    (
	vagrant destroy --force testing ||
	    echo "I really do not know why this fails from time to time, but as long as the instance is destroyed it is OK"
    ) &&
    time vagrant up testing --provider=aws &&
    echo The firewall is up and running. && 
    vagrant ssh testing -- "systemctl status firewalld.service | grep running" &&
    echo The instance was recently updated - within the last hour. &&
    LAST_UPDATED=$(vagrant ssh testing -- sudo dnf update --assumeyes | grep "Last metadata expiration check performed" | sed -e "s#^Last metadata expiration check performed .* ago on \(.*\)[.]\$#\1#") &&
    SECONDS_SINCE_LAST_UPDATE=$(($(vagrant ssh testing -- date +s)-$(date --date "${LAST_UPDATED}" +s))) &&
    if [[ $((60*60)) -lt ${SECOND_SINCE_LAST_UPDATE} ]]
    then
	echo We are failing because the last dnf update was done ${LAST_UPDATED}.
	exit 64 &&
	    true
    fi &&
    echo There is a docker command. &&
    vagrant ssh testing -- which docker &&
    echo The documer service is running. &&
    vagrant ssh testing -- "systemctl status docker.service | grep running" &&
    echo The regular user is a member of the docker group, so it can run without sudo. &&
    vagrant ssh testing -- "groups | grep docker" &&
    echo Verify that the regular user can run without sudo. &&
    vagrant ssh testing -- "docker info" &&
    vagrant ssh testing -- "if [ ! -d /home/fedora/docker ] ; then exit 64; fi" &&
    (
	vagrant destroy --force testing ||
	    echo "I really do not know why this fails from time to time, but as long as the instance is destroyed it is OK"
    ) &&
    true
