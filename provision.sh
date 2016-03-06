#!/bin/bash

ENVIRONMENT=${1} &&
    (cat <<EOF
Install and configure docker.
Environment is ${ENVIRONMENT}.

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
Install docker
EOF
    ) &&
    while ! dnf install --assumeyes docker*
    do
	sleep 1m &&
	    true
    done &&
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
    while ! dnf install --assumeyes docker* git
    do
	sleep 1m &&
	    true
    done &&
    (
	cat > /home/fedora/.ssh/PPl78Mfm_id_rsa <<EOF
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAlZJZ618IZW5AbINxbPc55JW36seN3VGcDZdbWdwf0aqpgdsv
tCQWDkFftikndZSk9RTfxI9plVUEKcpHItvcUxP+9qwR+lYSfAypEYiuv405MMeO
N2sTtBaP2YWpZRTXFMK2WRpPIBJg/ZKeLjwTNwOWnvzhko9PL5PADKeNFu8+mxp+
tSnGHSYJMM3q4QNMZMjlyqsm7wbelSO7snR2Zm5ZRyW08x7a+wcqJe7FEDh+Lk7V
sU61a5qJr5WFyd214+SOiXt1lVtK8N/jyTnIVG6r0UKLhLfJEGAybUm1OA4paQsR
at03N194rebP/F23Hy7ItaDltc8XJtfneVZPjwIDAQABAoIBAG0ZKiOH1vz9NVqx
abucfQrhthw3YKANVfGH9GcQK9loTWndsecI51mQj7q0PAcE3GmzxyB9pvr43yeI
VujzS7sBe9j7W8WooKUBKxUSCLzJyuxssqxzmxSh3F1CpHOJhvSqrg1CJnLzVPHA
z0ZUJYPcRzJCrFqV06GVeOECGeSekic83Eo1hZcei54C6h0PeIhGB5xpW9X9OzDL
pXSFJ6yWvVYUfyMd4Vy9SXIpGbqtdb5Nds39ltoRXs3GMo4N9EF/MVTDYZ5fdsfX
cHFV01D3fBlS5SJA/CG+a21P2ca0PKluqFNFi9QhAckGnj0EshLUWXXjzOHACHyy
Sn7ofPECgYEAxXucpjgc7Iat3zAxex0/o8wCtAozTY6CJTidk7riAOzOcMJ8fUHu
06R3GAHlfxLudw++msXXrIWuVZixXZ7hd/WcMCFhvqQoIc9gp45lM/VFyxyVRONX
jjo2Vd+pUjfbHYhkCauoBe1F+0uQpYst23jsfJXP36azzTmL77a9qPkCgYEAweRb
r8hJuZCe48ZzFQpdmAdf3Dxfyq9/jMSA8E708oiiJE+tKymr3MKU0I6lmHZgi23T
hkGBtW/7P0q9yijO7y8RoLCIV7XBZD8a+LowYdhv6QdpPrLHr+I8nsq2i+mSuPJr
cAlhKhq3dhRNWtnK6O2FFPf4uUxh7e9RH7srJscCgYEAq6QJfgrtUMKp4n9fslK0
mmfZvaPT/UesZC91/g2DGyy3LRhM3Q1uR3L9s9cKIc1RiBgeISVtk9xIrsrc9bL+
4qWNj+Ojse+5ldFJf7hqy6MVezinoE08Lzj3OuH/p582ic+eqy0QB763gXenC8sR
G11ZpdsL5qZcRjYLI1kgNPkCgYAnMoQ6oDIPWqZUg+0GBudu8aa2flobPql5isxK
SJwKYAbvclAe1rjQ02GEXCIsFVplNZm6nYmcZXwUioad1OwovIpCww19NdhX7M4G
FJXtYfUV1hK3wyrNat44d+C5nkm0LAX+S1ciTO5j56zPvhHgTwxFdfAJfeCaWnQ7
BvqtRwKBgDaDLyDz3lSFA3MPF2qvHzULFgOvYRPX1tW5FUwB5SKhyyZk88CAcc3f
UsifelLFZXLinTiaesNamB5iddY1PrfanicLklQeAV6G37r0S0KNC6jxhdMhAvo3
1CN3GVRkQu042zNMjv2yrS3fqZaK2LXfrBMCG+xxFT23rVZT9kQo
-----END RSA PRIVATE KEY-----
EOF
    ) &&
    chown fedora:fedora /home/fedora/.ssh/PPl78Mfm_id_rsa &&
    chmod 0600 /home/fedora/.ssh/PPl78Mfm_id_rsa &&
    (cat >> /home/fedora/.ssh/config <<EOF

Host github.com
User git
IdentityFile  /home/fedora/.ssh/PPl78Mfm_id_rsa
StrictHostKeyChecking no

EOF
    ) &&
    chown fedora:fedora /home/fedora/.ssh/config &&
    chmod 0600 /home/fedora/.ssh/config &&
    su --login fedora --command "mkdir --parents working/{jenkins-docker,systemd}" &&
    su --login fedora --command "git -C working/jenkins-docker init" &&
    su --login fedora --command "git -C working/jenkins-docker remote add github git@github.com:AFnRFCb7/jenkins-docker.git" &&
    su --login fedora --command "git -C working/systemd init" &&
    su --login fedora --command "git -C working/systemd remote add github git@github.com:AFnRFCb7/microphonegolden.git" &&
    (cat <<EOF
ENJOY!
EOF
    ) &&
    true
