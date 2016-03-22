#!/bin/bash

source /usr/local/src/private/credentials.sh &&
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
    echo Verify that we mounted a volume on /var/lib
    (
	[[ ! -z "$(vagrant ssh testing -- "df" | grep /dev/xvdf | grep /var/lib)" ]] || (
	    echo no volume &&
		exit 68 &&
		true
	)
    ) &&
    echo The documer service is running. &&
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
    (
	vagrant ssh testing -- "[[ -d /home/fedora/working ]]" || (
	    echo no working directory &&
		exit 69 &&
		true
	) &&
	    true
    ) &&
    (
	vagrant ssh testing -- "[[ -d /home/fedora/working/jenkins-docker/.git ]]" || (
	echo no working/jenkins-docker directory &&
	    exit 70 &&
	    true
	) &&
	    true
    ) &&
    (
	vagrant ssh testing -- "[[ \"* master\" == \"\$(git -C /home/fedora/working/jenkins-docker branch)\" ]]" || (
	    echo no working/jenkins-docker master &&
		exit 71 &&
		true
	) &&
	    true
    ) &&
    (
	vagrant ssh testing -- "[[ -d /home/fedora/working/systemd/.git ]]" || (
	    echo no working/systemd directory &&
		exit 72 &&
		true
	) &&
	    true
    ) &&
    (
	vagrant ssh testing -- "[[ \"* master\" == \"\$(git -C /home/fedora/working/systemd branch)\" ]]" || (
	    echo no working/systemd master &&
	    exit 73 &&
	    true
	) &&
	    true
    ) &&
    (
	vagrant ssh testing -- "[[ -d /home/fedora/working/desertedscorpion/abandonnedsmoke/.git ]]" || (
	    echo no working/desertedscorpion/abandonnedsmoke directory &&
		exit 74 &&
		true
	) &&
	    true
    ) &&
    (
	vagrant ssh testing -- "[[ \"* master\" == \"\$(git -C /home/fedora/working/desertedscorpion/abandonnedsmoke branch)\" ]]" || (
	    echo no working/desertedscorpion/abandonnedsmoke master &&
	    exit 75 &&
	    true
	) &&
	    true
    ) &&
    (
	vagrant ssh testing -- "[[ -d /home/fedora/working/desertedscorpion/strawsound/.git ]]" || (
	    echo no working/desertedscorpion/strawsound directory &&
		exit 74 &&
		true
	) &&
	    true
    ) &&
    (
	vagrant ssh testing -- "[[ \"* master\" == \"\$(git -C /home/fedora/working/desertedscorpion/strawsound branch)\" ]]" || (
	    echo no working/desertedscorpion/strawsound master &&
	    exit 75 &&
	    true
	) &&
	    true
    ) &&
    (
	vagrant ssh testing -- "[[ -d /home/fedora/working/desertedscorpion/needlessbeta/.git ]]" || (
	    echo no working/desertedscorpion/needlessbeta directory &&
		exit 74 &&
		true
	) &&
	    true
    ) &&
    (
	vagrant ssh testing -- "[[ \"* master\" == \"\$(git -C /home/fedora/working/desertedscorpion/needlessbeta branch)\" ]]" || (
	    echo no working/desertedscorpion/needlessbeta master &&
	    exit 75 &&
	    true
	) &&
	    true
    ) &&
    (
	vagrant ssh testing -- "[[ -d /home/fedora/working/desertedscorpion/braveoyster/.git ]]" || (
	    echo no working/desertedscorpion/braveoyster directory &&
		exit 74 &&
		true
	) &&
	    true
    ) &&
    (
	vagrant ssh testing -- "[[ \"* master\" == \"\$(git -C /home/fedora/working/desertedscorpion/braveoyster branch)\" ]]" || (
	    echo no working/desertedscorpion/braveoyster master &&
	    exit 75 &&
	    true
	) &&
	    true
    ) &&
    GIT_NAME=$(vagrant ssh testing -- grep name .gitconfig | sed -e "s#^\s*name\s*=\s*##") &&    
    echo verify git is configured with my name \"${GIT_NAME}\" &&
    [[ "Emory Merryman" == ${GIT_NAME} ]] &&
    GIT_EMAIL=$(vagrant ssh testing -- grep name .gitconfig | sed -e "s#^\s*email\s*=\s*##" -e "s#[+].*@#@#") &&
    echo verify git is configured with my email \"${GIT_EMAIL}\" &&
    [[ "emory.merryman@gmail.com" == ${GIT_EMAIL} ]] &&
    echo verify emacs is installed &&
    vagrant ssh testing -- which emacs &&
#    vagrant ssh testing -- "if [[ \"/usr/bin/emacs\" != \"\$(which emacs)\" ]] ; then echo no emacs && exit 66; fi" &&
    (
	vagrant ssh testing -- "[[ \"Username: ${DOCKER_USERID}\" == \"\$(docker info | grep Username)\" ]]" || (
	    echo not logged into docker &&
		exit 74 &&
		true
	) &&
	    true
    ) &&
    (
	vagrant destroy --force testing ||
	    echo "I really do not know why this fails from time to time, but as long as the instance is destroyed it is OK"
    ) &&
    true
