VPN_NAME := default
VPN_USER := guest
VPN_PASSWORD := hunter2
TF_VAR_pub_key := $(shell cat ./ec2-key.pub)
TF_VAR_aws_region := us-east-1
TF_VAR_aws_az := us-east-1d
TF_VAR_ami := ami-845367ff
ANSIBLE_ROLES_PATH := ./roles
ANSIBLE_CONFIG := ./ansible.cfg

export VPN_NAME VPN_USER VPN_PASSWORD
export ANSIBLE_CONFIG ANSIBLE_ROLES_PATH
export TF_VAR_ami TF_VAR_aws_az
export TF_VAR_aws_region TF_VAR_pub_key

# An implicit guard target, used by other targets to ensure
# that environment variables are set before beginning tasks
assert-%:
	@ if [ "${${*}}" = "" ]; then \
	    echo "Environment variable $* not set"; \
	    exit 1; \
	fi

vpn:
	@read -p "Enter AWS Profile Name: " profile; \
	TF_VAR_aws_profile=$$profile make keypair; \
	TF_VAR_aws_profile=$$profile make apply; \
	TF_VAR_aws_profile=$$profile make reprovision

require-ansible:
	ansible --version &> /dev/null

require-tf:
	terraform --version &> /dev/null

require-jq:
	jq --version &> /dev/null

keypair:
	ssh-keygen -N '' -f ec2-key

plan: assert-TF_VAR_aws_profile require-tf
	terraform plan

ansible-roles:
	ansible-galaxy install -r requirements.yml

apply: assert-TF_VAR_aws_profile require-tf require-ansible ansible-roles
	@ if [ -z "$TF_VAR_pub_key" ]; then \
		echo "\$TF_VAR_pub_key is empty; run 'make keypair' first!"; \
		exit 1; \
	fi
	terraform apply

build: apply

ssh:
	ssh \
	 -i ./ec2-key \
	 -l ubuntu \
	 `terraform output -json|jq -r ".ip.value"`

plan-destroy:
	terraform plan -destroy

destroy:
	terraform destroy

clean: destroy

reprovision: require-jq
	ansible-playbook \
	 -e vpn_name=${VPN_NAME} \
	 -e vpn_user=${VPN_USER} \
	 -e vpn_password=${VPN_PASSWORD} \
	 -i `terraform output -json|jq -r ".ip.value"`, \
	 ./openvpn.yml
