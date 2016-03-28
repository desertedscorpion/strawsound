#!/bin/bash

export DOCKER_USERID=$(cat private.initial/docker_userid) &&
    export DOCKER_PASSWORD=$(cat private.initial/docker_password) &&
    export DOCKER_EMAIL=$(cat private.initial/docker_email) &&
    export ACCESS_KEY_ID=$(cat private.initial/access_key_id) &&
    export SECRET_ACCESS_KEY=$(cat private.initial/secret_access_key) &&
    export GITHUB_STRAWSOUND_PRIVATE_SSH_KEY=$(cat private.initial/OpGlyegL_id_rsa) &&
    export GITHUB_STRAWSOUND_PUBLIC_SSH_KEY=$(cat private.initial/OpGlyegL_id_rsa) &&
    (
	vagrant destroy --force initial ||
	    echo "I really do not know why this fails from time to time, but as long as the instance is destroyed it is OK"
    ) &&
    time vagrant up initial --provider=aws &&
    true
