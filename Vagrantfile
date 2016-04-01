# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.configure(2) do |config|
  config.vm.box = "dummy"
  config.vm.define "initial" do |box|
    box.vm.provision "shell", path: "provision.sh", args: ["initial", ENV["BRANCH"], ENV["DOCKER_USERID"], ENV["DOCKER_PASSWORD"], ENV["DOCKER_EMAIL"], ENV["ACCESS_KEY_ID"], ENV["SECRET_ACCESS_KEY"], ENV["GITHUB_STRAWSOUND_PRIVATE_SSH_KEY"], ENV["GITHUB_STRAWSOUND_PUBLIC_SSH_KEY"], ENV["GITNAME"], ENV["GITEMAIL"]]
    box.vm.synced_folder ".", "/vagrant", type: "rsync", disabled: true
    box.vm.provider :aws do |aws, override|
      aws.access_key_id = ENV["ACCESS_KEY_ID"]
      aws.secret_access_key = ENV["SECRET_ACCESS_KEY"]
      aws.keypair_name = "docker"
      aws.security_groups = ["docker"]
      aws.availability_zone = "us-east-1a"
      aws.tags = {
        "Name" => "docker",
        "Environment" => "initial",
        "Branch" => ENV["BRANCH"]
      }
      aws.ami = "ami-02321068"
      override.ssh.username = "fedora"
      override.ssh.private_key_path = "private/initial/aws/docker.pem"
    end
  end
  config.vm.define "testing" do |box|
    box.vm.provision "shell", path: "provision.sh", args: ["testing", ENV["BRANCH"], ENV["DOCKER_USERID"], ENV["DOCKER_PASSWORD"], ENV["DOCKER_EMAIL"], ENV["ACCESS_KEY_ID"], ENV["SECRET_ACCESS_KEY"], ENV["GITHUB_STRAWSOUND_PRIVATE_SSH_KEY"], ENV["GITHUB_STRAWSOUND_PUBLIC_SSH_KEY"], ENV["GITNAME"], ENV["GITEMAIL"]]
    box.vm.synced_folder ".", "/vagrant", type: "rsync", disabled: true
    box.vm.provider :aws do |aws, override|
      aws.access_key_id = ENV["ACCESS_KEY_ID"]
      aws.secret_access_key = ENV["SECRET_ACCESS_KEY"]
      aws.keypair_name = "docker"
      aws.security_groups = ["docker"]
      aws.availability_zone = "us-east-1a"
      aws.tags = {
        "Name" => "docker",
        "Environment" => "testing",
        "Branch" => ENV["BRANCH"]
      }
      aws.ami = "ami-02321068"
      override.ssh.username = "fedora"
      override.ssh.private_key_path = "private/testing/aws/docker.pem"
    end
  end
end
