#!/bin/bash

ENVIRONMENT="${1}" &&
    DOCKER_USERID="${2}" &&
    DOCKER_PASSWORD="${3}" &&
    DOCKER_EMAIL="${4}" &&
    ACCESS_KEY_ID="${5}" &&
    SECRET_ACCESS_KEY="${6}" &&
    GITHUB_STRAWSOUND_PRIVATE_SSH_KEY="${7}" &&
    GITHUB_STRAWSOUND_PUBLIC_SSH_KEY="${8}" &&
    GITNAME="${9}" &&
    GITEMAIL="${10}" &&
    (cat <<EOF
Install and configure docker.
Environment is ${ENVIRONMENT}.
The Docker credentials are ${DOCKER_USERID}, ${DOCKER_PASSWORD}, and ${DOCKER_EMAIL}.

We need to install, start, and enable firewalld because the minimal fedora cloud image does not have it.
EOF
) &&
    while ! dnf install --assumeyes firewalld
    do
	sleep 60s &&
	    true
    done
    systemctl start firewalld.service &&
    systemctl enable firewalld.service &&
    (cat <<EOF
Update the system
EOF
    ) &&
    while ! dnf update --assumeyes
    do
	sleep 1m &&
	    true
    done &&
    (cat <<EOF
Install aws command line tools.
EOF
     ) &&
    while ! dnf install --assumeyes zip python wget
    do
	sleep 60s &&
	    true
    done &&
    cd $(mktemp -d) &&
    while ! curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
    do
	sleep 60s &&
	    true
    done
    unzip awscli-bundle.zip &&
    ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws &&
    (cat <<EOF
${ACCESS_KEY_ID}
${SECRET_ACCESS_KEY}
us-east-1
text
EOF
    ) | /usr/local/bin/aws configure &&
    (cat <<EOF
Install docker
EOF
    ) &&    
    while ! dnf install --assumeyes docker*
    do
	sleep 1m &&
	    true
    done &&
    (cat <<EOF
Let us delete every volume associated with name=docker environment=${ENVIRONMENT}
Then we will create a new one.
That way we can be sure there is only exactly one.
EOF
    ) &&
    INSTANCE_ID=$(/usr/local/bin/aws ec2 describe-instances --filters "Name=tag:Name,Values=docker" "Name=tag:Environment,Values=${ENVIRONMENT}" "Name=instance-state-name,Values=running" | grep INSTANCES | cut --fields 8) &&
    /usr/local/bin/aws ec2 describe-volumes --filters "Name=tag:Name,Values=docker" "Name=tag:Environment,Values=${ENVIRONMENT}" | grep VOLUMES | wc --lines | grep VOLUMES | cut --fields 2 | while read VOLUME_ID
    do
	echo /usr/local/bin/aws ec2 delete-volume --volume-id ${VOLUME_ID} &&
	    /usr/local/bin/aws ec2 delete-volume --volume-id ${VOLUME_ID} &&
	    true
    done &&
    VOLUME_ID=$(/usr/local/bin/aws ec2 create-volume --size 10 --availability-zone us-east-1a | cut --fields 7) &&
    echo /usr/local/bin/aws ec2 create-tags --resources ${VOLUME_ID} --tags Key=Name,Value=docker Key=Environment,Value=${ENVIRONMENT} &&
    /usr/local/bin/aws ec2 create-tags --resources ${VOLUME_ID} --tags Key=Name,Value=docker Key=Environment,Value=${ENVIRONMENT} &&
    sleep 1m &&
    echo /usr/local/bin/aws ec2 attach-volume --volume-id ${VOLUME_ID} --instance-id ${INSTANCE_ID} --device /dev/xvdf &&
    /usr/local/bin/aws ec2 attach-volume --volume-id ${VOLUME_ID} --instance-id ${INSTANCE_ID} --device /dev/xvdf &&
    sleep 1m &&
    sleep 60s &&
    (cat <<EOF
The docker volume is not formatted.
Let's format it and mount it.
EOF
    ) &&
    mkfs.ext4 /dev/xvdf &&
    echo /dev/xvdf /var/lib/docker                   ext4    defaults,x-systemd.device-timeout=0 1 2 >> /etc/fstab &&
    mount /var/lib/docker &&
    (cat <<EOF
Start and enable the docker service
EOF
    ) &&
    systemctl start docker.service &&
    systemctl enable docker.service &&
    (cat <<EOF
Add the user to the docker group for sudo free usage
The docker group does not already exist.
We must restart the docker service in order for the user to be able
to use it.
EOF
    ) &&
    groupadd docker &&
    usermod -a -G docker fedora &&
    systemctl restart docker.service &&
    (cat <<EOF
Install git.
Configure git.
Clone our repo from github.
EOF
     ) &&
    while ! dnf install --assumeyes git
    do
	sleep 1m &&
	    true
    done &&
    GITHUB_STRAWSOUND_SSH_KEYFILE=$(mktemp /home/fedora/.ssh/XXXXXXXX_id_rsa) &&
    echo ${GITHUB_STRAWSOUND_PRIVATE_SSH_KEY} > \${GITHUB_STRAWSOUND_SSH_KEYFILE} &&
    chown fedora:fedora \${GITHUB_STRAWSOUND_SSH_KEYFILE} && &&
    chmod 0600 \${GITHUB_STRAWSOUND_SSH_KEYFILE} && &&
    (cat >> /home/fedora/.ssh/config <<EOF

Host github.com
User git
IdentityFile  \${GITHUB_STRAWSOUND_SSH_KEYFILE} &&
StrictHostKeyChecking no

EOF
    ) &&
    su --login fedora --command "git config --global user.name \"${GIT_NAME}\"" &&
    su --login fedora --command "git config --global user.email emory.merryman+\$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)@gmail.com" &&
    chown fedora:fedora /home/fedora/.ssh/config &&
    chmod 0600 /home/fedora/.ssh/config &&
    su --login fedora --command "echo docker login --username ${DOCKER_USERID} --password ${DOCKER_PASSWORD} --email ${DOCKER_EMAIL} https://index.docker.io/v1/" &&
    su --login fedora --command "docker login --username ${DOCKER_USERID} --password ${DOCKER_PASSWORD} --email ${DOCKER_EMAIL} https://index.docker.io/v1/" &&
    echo ENJOY!!!!!! &&
    true
