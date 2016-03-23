#!/bin/bash

source /usr/local/src/private/credentials.sh &&
    (
	vagrant destroy --force initial ||
	    echo "I really do not know why this fails from time to time, but as long as the instance is destroyed it is OK"
    ) &&
    true
