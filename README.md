## About

This project is a top-to-bottom [OpenVPN](https://openvpn.net/) setup for ubuntu on AWS, using Terraform to create the EC2 resources and security groups, and Ansible to setup VPN users.

In terms of server configuration, the heavy lifting for this project is mostly courtesy of the excellent [Stouts.openvpn](https://github.com/Stouts/Stouts.openvpn) ansible role.  What this repository does on top of that is:

  * pin the Ansible role and the Ubuntu AMI at known-working versions
  * add extra Ansible to forward *everything* from clients through the VPN
  * provide modular Terraform that sets up the AWS server/security groups to work with OpenVPN
  * provide a Makefile helps to execute both the Terraform and the Ansible and inject parameters from environment variables

## Prerequisites

Valid named AWS profiles should already be setup in your `~/.aws/credentials` file.  We'll assume in the rest of this guide that the profile you want to use is called `MY_PROFILE`.

You'll also need local copies of `terraform`, `ansible`, and `jq`.  My (confirmed working) version info follows:

    $ terraform --version
    Terraform v0.9.11

    $ ansible --version
    ansible 2.3.2.0

    $ jq --version
    jq-1.5

**Terraform** builds infrastructure resources on clouds like AWS.  It can be downloaded [here](https://www.terraform.io/downloads.html) or you could [use docker](https://hub.docker.com/r/hashicorp/terraform/).  If you prefer docker, just set an appropriate bash alias before using the Makefile.

**Ansible** configures resources on clouds with certain system packages, files, etc.  Installation is described in detail  [here](http://docs.ansible.com/ansible/latest/intro_installation.html), but for platforms that already have a python stack you can probably just run `pip install -r requirements.txt` in this directory.

**[Jq](https://stedolan.github.io/jq/)** is a sed-like tool for parsing JSON from the command line.  On OSX it can be installed with `brew install jq`

## Quick Start

1. Edit the [Makefile](Makefile) directly to change the primary VPN user's default username/password. Edit the ansible file [openvpn.yml](openvpn.yml) to add additional VPN users.

2. Afterwards, run `make vpn` and answer when it asks for the named AWS profile to use.  When this finishes an OpenVPN will be setup and ready to go, so you just need to configure a client.  After this step is completed, there are several new files in the working directory which will be used for that configuration.

3. As a VPN client, I recommend [tunnelblick](https://tunnelblick.net), where setup is especially easy.  Drag the new `default.ovpn` file inside the working directory onto the tunnelblick icon in the menubar and connect with the user/password you set in the Makefile.  Done!  You can verify your configuration by visiting a place like [http://www.whatsmyip.org/](http://www.whatsmyip.org/).

## Step by Step

This section is just a walk through of the individual steps you can run that `make vpn` would do magically for you.  Follow this instead of the quickstart above if you want to understand more about what's going on.

1. Generate a new ssh-key for EC2/terraform:

    $ make keypair

2. Set an environment variable that terraform will use for your AWS profile, and run `terraform plan` via the Makefile.  Inspect the plan and make sure it's what you expected.

    $ TF_VAR_aws_profile=MY_PROFILE make plan

3. Set an environment variable that terraform will use for your AWS profile, and run `terraform apply` via the Makefile.  This will create an EC2 server on AWS, together with the security groups and rules you'll need to use OpenVPN.

    $ TF_VAR_aws_profile=MY_PROFILE make apply

4. Edit the [Makefile](Makefile) directly to change the primary VPN user's default username/password. Edit the ansible file [openvpn.yml](openvpn.yml) to add additional VPN users. You can safely rerun the ansible provisioner as many times as you like to add/edit/remove VPN users (see the next step).

5.  To reprovision the VPN server, use the command below.  (The IP address of the host is determined automatically for you with the results of `terraform output`)

    $ make reprovision

5. If you need to connect to the OpenVPN server itself, there's a make target for that which will use the correct ssh user/keys.  (The IP address of the host is determined automatically for you with the results of `terraform output`)

    $ make ssh

6. If you want to tear things down again, you can use `make plan-destroy` to show the plan, and `make destroy` to actually clean up.

## Discussion, Limitations, Etc

A Makefile is provided in this project to call Terraform and Ansible consistently, and with consistent environment variables.  Not everyone who reads/writes terraform can read/write Ansible and vice versa, so as a compromise I'm mostly trying to use the Makefile to get information into both systems rather than using Ansible to drive Terraform or Terraform to drive Ansible.

I've also chosen to do a "two stage" setup with resource creation/provision handled separately, rather than using ansible via terraform's [local-exec provisioner](https://www.terraform.io/docs/provisioners/local-exec.html).  Reprovisioning in terraform is awkward at best, black magic at worst.  See [this discussion](https://github.com/hashicorp/terraform/issues/3193) for some workarounds if this is intolerable for your use-case.

Terraform resources are also arranged as modules, partly just to demonstrate modules.  Nevertheless this might be useful if you want to, for instance, eliminate bastions for multiple VPCs by instantiating multiple OpenVPN servers.  Note that individual OpenVPN servers can also support multiple VPNs, but we use one by default.

There are a variety of ways to override things at the Terraform layer (i.e. AWS region etc) which can be potentially confusing.  There's the [vars.tf](vars.tf) file where you can modify things directly by changing/adding defaults.  There's also the  [TF_VAR_name](https://www.terraform.io/docs/configuration/environment-variables.html#tf_var_name) trick, if you want to set values using environment variables.  There's also the openvpn module instantiation in [main.tf](main.tf) which allows for overrides.

For overriding things at the OpenVPN configuration layer, things are simpler.  Go have a close reading of the documentation for the [Stouts.openvpn](https://github.com/Stouts/Stouts.openvpn) role, which does almost all the real work here anyway.  Consider adding variables that it understands/supports.  Otherwise, you can always just pile new Ansible into the [openvpn.yml](openvpn.yml) file to override cert files with your own uploads, etc.

## Pull Requests

Are welcome
