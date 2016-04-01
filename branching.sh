#!/bin/bash

function branching() {
    cd $(mktemp -d) &&
	git clone git@github.com:desertedscorpion/strawsound.git &&
	cd strawsound &&
	git checkout master &&
	git checkout -b branch-$(printf %04d $((${RANDOM}%10000)))-$(echo "${@}" | tr [" "] [_]) &&
	ln -sf ${HOME}/working/desertedscorpion/strawsound/private . &&
	true
} &&
    true
