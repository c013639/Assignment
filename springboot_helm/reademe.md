##########################----Objective------#####################################################
In this module we shall deploy springboot application using helm chart. We included Dockerfile and already build jar file in the module directory.

##################################-----------Install HELM on Ubuntu System-------##################
Install helm using helm.yml playbook mentioned inside ansible_install_helm module.

#################################-----------Setup springboot application-----######################
using following commands to build and publish mentioned dockerfile as a image.

docker build -t springboot .
docker tag springboot:latest mohdadilqa/validateme-be-repo:latest
docker push mohdadilqa/validateme-be-repo:latest

I made above repo public so that anyone can easily pull and run the image.

Well enough with the per-requisites , lets run some Helm Commands for creating our sprinboot Helm Chart

helm create springboot

Update the repository and port field with the value "mohdadilqa/validateme-be-repo:latest" and "8080" respectively inside the values.yml file.

Update these two parameters in each manifest using below template command.

helm template springboot

After running the above commmand it returned pre-configured manifest configuration values, we copied all these values in our respective manifest file.

The next check which we are going to do is -dry-run. Helm is full of such useful utility which allows developer to test its configuration before running the final install command

helm install springboot --debug --dry-run springboot

Alright lets run the install command.

helm install myfirstspringboot springboot


Verfiy the deployment using 

helm list -a
kubectl get all



