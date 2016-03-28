#!/bin/bash

(cat <<EOF
Inspiration and reference:  http://redsymbol.net/articles/bash-exit-traps/
I don't really understand traps and the below code is untested.

The goal is that whenever the system finishes (even if it fails)
it should destroy the testing machine.

This is b/c we have found that multiple instances of the testing
machine can confuse the tests and cause errors.

If we are still having multiple instances of the testing machine,
then this code is not working.
EOF
) &&
    function finish(){
	(
	    vagrant destroy --force testing ||
		echo "I really do not know why this fails from time to time, but as long as the instance is destroyed it is OK"
	) &&
	    true
    } &&
    trap finish EXIT &&
    export BRANCH=$(git rev-parse --abbrev-ref HEAD) &&
    export DOCKER_USERID=$(cat private/testing/docker/docker_userid) &&
    export DOCKER_PASSWORD=$(cat private/testing/docker/docker_password) &&
    export DOCKER_EMAIL=$(cat private/testing/docker/docker_email) &&
    export ACCESS_KEY_ID=$(cat private/testing/aws/access_key_id) &&
    export SECRET_ACCESS_KEY=$(cat private/testing/aws/secret_access_key) &&
    export GITHUB_STRAWSOUND_PRIVATE_SSH_KEY=$(cat private/testing/github/strawsound_id_rsa) &&
    export GITHUB_STRAWSOUND_PUBLIC_SSH_KEY=$(cat private/testing/github/strawsound_id_rsa.pub)
export GITNAME=$(cat private/testing/git/name) &&
    export GITEMAIL=$(private/initial/git/email.sh) &&
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
	echo We are failing because the last dnf update was done ${LAST_UPDATED}. &&
	    exit 64 &&
	    true
    fi &&
    echo There is a docker command. &&
    vagrant ssh testing -- which docker &&
    echo Verify that we mounted a volume on /var/lib &&
    (
	[[ ! -z "$(vagrant ssh testing -- "df" | grep /dev/xvdf | grep /var/lib)" ]] || (
	    echo no volume &&
		exit 68 &&
		true
	)
    ) &&
    echo The docker service is running. &&
    vagrant ssh testing -- "systemctl status docker.service | grep running" &&
    echo The regular user is a member of the docker group, so it can run without sudo. &&
    vagrant ssh testing -- "groups | grep docker" &&
    echo Verify that the regular user can run without sudo. &&
    sleep 1m &&
    vagrant ssh testing -- "docker info" &&
    (cat <<EOF
Here we are cloning a simple hello world application.
Then we will try to use it.
We are following http://docs.aws.amazon.com/AmazonECS/latest/developerguide/docker-basics.html to a large extent.
EOF
    ) &&
    echo verify git configuration &&
    [[ ${GITNAME} == $(vagrant ssh testing -- grep name .gitconfig | sed -e "s#^\s*name\s*=\s*##") ]] &&    
    [[ ${GITEMAIL} == $(vagrant ssh testing -- grep email .gitconfig | sed -e "s#^\s*email\s*=\s*##") ]] &&
    echo let us dockerize for verification &&
    vagrant ssh testing -- mkdir --parents /home/fedora/testing/desertedscorpion
echo Let us test with a simple node express hello world application &&
    vagrant ssh testing -- git -C /home/fedora/testing/desertedscorpion clone git@github.com:desertedscorpion/subtleostrich.git &&
    echo build the docker image from the Dockerfile &&
    vagrant ssh testing -- "cd /home/fedora/testing/desertedscorpion/subtleostrich && docker build -t taf7lwappqystqp4u7wjsqkdc7dquw/homelessbreeze_subtleostrict ." &&
    echo verify that the image was created correctly and that the image file contains a repository we can push to &&
    vagrant ssh testing -- "cd /home/fedora/testing/helloworld && docker images | grep taf7lwappqystqp4u7wjsqkdc7dquw/homelessbreeze_subtleostrict" &&
    vagrant ssh testing -- "cd /home/fedora/testing/helloworld && docker run -p 3000:3000 -d taf7lwappqystqp4u7wjsqkdc7dquw/homelessbreeze_subtleostrict && echo ${?}" > ${WORK_DIR}/run.txt 2>&1 &&
    vagrant ssh testing -- "curl -s http://localhost:3000" > ${WORK_DIR}/curl.txt 2>&1 &&
    if [[ "Hello World!" != "$(cat ${WORK_DIR}/curl.txt)" ]]
    then
	echo the server did not work &&
	    exit 64 &&
	    true
    fi &&
    true
