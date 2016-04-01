#!/bin/bash

export ACCESS_KEY_ID=$(cat private/initial/aws/access_key_id) &&
    export SECRET_ACCESS_KEY=$(cat private/initial/aws/secret_access_key) &&
    vagrant ssh initial &&
    true
