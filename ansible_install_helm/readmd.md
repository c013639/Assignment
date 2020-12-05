##################----helm.yml----#########################
This playbook is used to install helm chart on AWS cloud EC2 servers,configured to converge only one server.

########################################---Dynamic Inventory Setup----#####################
Prerequisites:
1. Install Python3 or more on source system
2. Install ansible,boto and aws cli using pip

$ sudo apt update
$ sudo apt install software-properties-common
$ sudo apt-add-repository --yes --update ppa:ansible/ansible
$ sudo apt install ansible
$ sudo pip install boto

3. Run aws configure to set default AWS profile
AWS_ACCESS_KEY_ID='YOUR_AWS_API_KEY'
AWS_SECRET_ACCESS_KEY='YOUR_AWS_API_SECRET_KEY'
AWS_Region='us-east-1'

To get started with dynamic inventory management, you’ll need to grab the EC2.py script and the EC2.ini config file. The EC2.py script is written using the Boto EC2 library and will query AWS for your running Amazon EC2 instances. The EC2.ini file is the config file for EC2.py, and can be used to limit the scope of Ansible’s reach. You can specify the regions, instance tags, or roles that the EC2.py script will find. Personally, I’ve scoped Ansible to just look at the US-east-1 region.

$ export ANSIBLE_HOSTS=/etc/ansible/ec2.py This tells Ansible to use the dynamic EC2 script instead of a static /etc/ansible/hosts file.

$ export EC2_INI_PATH=/etc/ansible/ec2.ini This tells ec2.py where the ec2.ini config file is located.

Using an SSH agent is the best way to authenticate with your end nodes, as this alleviates the need to copy your .pem files around. To add an agent, do

$ ssh-agent bash 
$ ssh-add ~/.ssh/keypair.pem 

At this stage, you should be ready to communicate with your instances. Here’s your post checklist:

-Ansible is installed and has access to your Secret and Access key 
-Ec2.py and Ec2.ini inventory scripts are downloaded and configured
-ANSIBLE_HOSTS environment variable set
-Ansible.cfg exists
-SSH agent is running (You can check with “ssh-add -L”)

If you call the Amazon EC2 inventory script directly, you’ll see your Amazon EC2 inventory broken down and grouped by a variety of factors. To try this, run $ /etc/ansible/ec2.py --list


At the end run playbook to install helm on one of your EC2 server.

$ ansible-playbook helm.yml
