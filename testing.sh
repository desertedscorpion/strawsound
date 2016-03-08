#!/bin/bash

source credentials.sh &&
    (cat <<EOF
Test the docker provisioning script.
We destroy the docker testing instance (if it exists).
Then create it fresh.
We verify that the machine has been recently updated.
We verify that we can use docker.
We verify that a certain set of git projects have been cloned.
(Whether those projects work or not is outside the scope of this test.)
Then we destroy the docker testing instance.
EOF
) &&
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
    (cat <<EOF
Here we are cloning a simple hello world application.
Then we will try to use it.
We are following http://docs.aws.amazon.com/AmazonECS/latest/developerguide/docker-basics.html to a large extent.
EOF
    ) &&
    vagrant ssh testing -- "mkdir testing" &&
    WORK_DIR=$(mktemp -d) &&
    tar --create --file ${WORK_DIR}/testing.tar testing &&
    vagrant scp ${WORK_DIR}/testing.tar testing:/tmp &&
    vagrant ssh testing -- "tar --extract --file /tmp/testing.tar" &&
    (cat <<EOF
Let us test with a simple node application.
EOF
    ) &&
    echo build the docker image from the Dockerfile &&
    vagrant ssh testing -- "cd /home/fedora/testing/helloworld && docker build -t taf7lwappqystqp4u7wjsqkdc7dquw/docker-helloworld ." &&
    echo verify that the image was created correctly and that the image file contains a repository we can push to && 
    vagrant ssh testing -- "cd /home/fedora/testing/helloworld && docker images" > ${WORK_DIR}/images.txt 2>&1 &&
    (cat <<EOF
We are testing that the images output has 3 lines and the second line has the test image repository.
The output should look like

REPOSITORY                                         TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
taf7lwappqystqp4u7wjsqkdc7dquw/docker-helloworld   latest              3054725ef24a        13 minutes ago      490.4 MB
docker.io/centos                                   centos6             ed452988fb6e        19 hours ago        228.9 MB


THe first line is just header.
The second line is about our test project.
The third line is a layer underneath our test project.
EOF
     ) &&
    if [[ "3" != $(wc --lines ${WORK_DIR}/images.txt | cut --fields 1 --delimiter " ") ]]
    then
	echo the images should consist of 3 lines &&
	    cat ${WORK_DIR}/images.txt &&
	    exit 64 &&
	    true
    elif [[ "taf7lwappqystqp4u7wjsqkdc7dquw/docker-helloworld" != $(head ${WORK_DIR}/images.txt --lines 2 | tail --lines 1 | cut --fields 1 --delim " ") ]]
    then
	echo the images should have the test repository &&
	    cat ${WORK_DIR}/images.txt &&
	    exit 64 &&
	    true
    fi &&
    vagrant ssh testing -- "cd /home/fedora/testing/helloworld && docker run -p 3000:3000 -d taf7lwappqystqp4u7wjsqkdc7dquw/docker-helloworld && echo ${?}" > ${WORK_DIR}/run.txt 2>&1 &&
    vagrant ssh testing -- "curl -s http://localhost:3000" > ${WORK_DIR}/curl.txt 2>&1 &&
    if [[ "Hello World!" != "$(cat ${WORK_DIR}/curl.txt)" ]]
    then
	echo the server did not work &&
	    exit 64
	    true
    fi &&
    (cat <<EOF
Let us verify that all our working stuff is there.
EOF
     ) &&
    vagrant ssh testing -- "if [[ ! -d /home/fedora/working ]] ; then echo no working directory && exit 64; fi" &&
    vagrant ssh testing -- "if [[ ! -d /home/fedora/working/jenkins-docker/.git ]] ; then echo no working/jenkins-docker directory && exit 65; fi" &&
    vagrant ssh testing -- "if [[ \"* master\" != \"\$(git -C /home/fedora/working/jenkins-docker branch)\" ]] ; then echo no working/jenkins-docker directory master && exit 65; fi" &&
    vagrant ssh testing -- "if [[ ! -d /home/fedora/working/systemd/.git ]] ; then echo no working/systemd directory && exit 65; fi" &&
    vagrant ssh testing -- "if [[ \"* master\" != \"\$(git -C /home/fedora/working/systemd branch)\" ]] ; then echo no working/systemd directory master && exit 65; fi" &&
    vagrant ssh testing -- "if [[ \"/usr/bin/emacs\" != \"\$(which emacs)\" ]] ; then echo no emacs && exit 66; fi" &&
    (
	vagrant destroy --force testing ||
	    echo "I really do not know why this fails from time to time, but as long as the instance is destroyed it is OK"
    ) &&
    true
