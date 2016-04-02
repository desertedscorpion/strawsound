#!/bin/bash

export BRANCH=$(git rev-parse --abbrev-ref HEAD) &&
    export DOCKER_USERID=$(cat private/initial/docker/docker_userid) &&
    export DOCKER_PASSWORD=$(cat private/initial/docker/docker_password) &&
    export DOCKER_EMAIL=$(cat private/initial/docker/docker_email) &&
    export ACCESS_KEY_ID=$(cat private/initial/aws/access_key_id) &&
    export SECRET_ACCESS_KEY=$(cat private/initial/aws/secret_access_key) &&
    export GITHUB_STRAWSOUND_PRIVATE_SSH_KEY=$(cat private/initial/github/strawsound_id_rsa) &&
    export GITHUB_STRAWSOUND_PUBLIC_SSH_KEY=$(cat private/initial/github/strawsound_id_rsa.pub) &&
    export GITNAME=$(cat private/initial/git/name) &&
    export GITEMAIL=$(private/initial/git/email.sh) &&
    vagrant ssh initial &&
    true
