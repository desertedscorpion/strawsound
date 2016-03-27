#!/bin/bash

source /usr/local/src/private/credentials.sh &&
    (
	vagrant destroy --force initial ||
	    echo "I really do not know why this fails from time to time, but as long as the instance is destroyed it is OK"
    ) &&
    time vagrant up initial --provider=aws &&
    vagrant scp private/credentials.sh initial:/home/fedora/working/desertedscorpion/abandonnedsmoke/private &&
    vagrant scp private/xSGyYmpH_id_rsa initial:/home/fedora/working/desertedscorpion/abandonnedsmoke/private &&
    vagrant scp private/credentials.sh initial:/home/fedora/working/desertedscorpion/strawsound/private &&
    vagrant scp private/xSGyYmpH_id_rsa initial:/home/fedora/working/desertedscorpion/strawsound/private &&
    true
