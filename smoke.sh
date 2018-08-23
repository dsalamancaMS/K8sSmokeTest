#!/bin/bash
{
NC='\033[0m'
GREEN='\033[1;32m'
RED='\033[1;31m'
BLUE='\033[1;34m'
PRPL='\033[1;35m'

> results.txt
 echo -e '-------------------- Testing Kube Components --------------------'


date >> results.txt

echo -e "\n--------Test #1 - Namespace creation--------" 

echo -e "\n >>>>>>>>>> Creating Namespace"

kubectl create namespace testspace 

# echo -e "\n--------Test #2 - Pod & image Pull--------" 

# echo -e '\n >>>>>>>>>> Pulling Image and Creating Pod'

# cat << EOF | kubectl create -f - 
# apiVersion: v1
# kind: Pod
# metadata:
#   namespace: testspace
#   name: image-pull-test
# spec:
#   restartPolicy: Never
#   containers:
#   - name: image-test
#     image: busybox
#     imagePullPolicy: Always
#     args:
#     - echo
#     - "success" 
# EOF


# echo -e "\n--------Test #3 - Communication Between Pods--------" 

# echo -e "\n >>>>>>>>>> Creating Pods for Test"

# #remember to change sleep
# cat << EOF | kubectl create -f - 
# apiVersion: apps/v1
# kind: DaemonSet
# metadata:
#   namespace: testspace
#   name: ping-daemons
#   labels:
#     ping: test
# spec:
#   selector:
#     matchLabels:
#       ping: pods
#   template:
#     metadata:
#       labels:
#         ping: pods
#     spec:
#       containers:
#       - name: ping-pod
#         image: busybox:1.27
#         args:
#         - sleep
#         - "10000"
# EOF


# sleep 60

######## Remember to put Timer

function get_ping_ips() {

kubectl get po -n testspace -l ping=pods -o json | grep -i "podIP" | awk '{print $2}' | sed 's/[",]//g'

}

function get_ping_pods() {

kubectl get pods -n testspace | grep ping-daemons | awk '{print $1}' 

}


# echo -e "\n>>>>Testing connectivity from $(get_ping_pods | head -1) to $(get_ping_pods | tail -1)\n" 

# kubectl exec -n testspace $(get_ping_pods | head -1) -it -- ping -c 4 $(get_ping_ips | tail -1)  

# echo -e "\n>>>>Testing connectivity from $(get_ping_pods | head -1) to $(get_ping_pods | tail -1)\n" 

# kubectl exec -n testspace $(get_ping_pods | tail -1) -it -- ping -c 4 $(get_ping_ips | head -1) 

# echo -e "\n--------Test #4 - Public DNS Lookup--------" 

# for i in $(get_ping_pods)
# do
#     echo -e "\n>>>>Testing Public DNS lookup on $i\n"
#     kubectl exec -n testspace $i -- nslookup google.com
# done



    

# Test 5 deployment constructor
function t5_deploy_constr() {

echo -e "\n--------Test #5 Deployment Tests--------" 

echo -e "\n>>>>Creating Deployment for Testing\n"
cat << EOF | kubectl create -f - 
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: testspace
  name: deploy-test
  labels:
    deploy: test
spec:
  replicas: 3
  selector:
    matchLabels:
      deploy: test
  template:
    metadata:
      labels:
        deploy: test
    spec:
      containers:
      - name: deploy-test-pod
        image: nginx:1.7.9
        ports:
        - containerPort: 80
EOF

}


#Variable to get pods
t5_pods="kubectl get po -n testspace -l deploy=test"


#Test 5 get deployment
function t5_get_deploy(){
    
    kubectl get deploy -n testspace deploy-test
}

#Test 5 watches the changes on the deployment pods for 30sec
function t5_watch_deploy(){
  timeout 30 $t5_pods --watch
}


#Test 5 peforms a rolloing update of the image
function t5_deploy_img_upd(){
  
  kubectl set image -n testspace deploy/deploy-test  deploy-test-pod=nginx:1.9.1 --record
  echo -e "\n"
  kubectl rollout status deployment/deploy-test  -n testspace
  echo -e "\n"
  t5_watch_deploy
  echo -e "\n"
  t5_deploy_hist

}


#Test 5 Function to see the rollout history of the deployment
function t5_deploy_hist(){

  kubectl rollout history -n testspace deploy/deploy-test 
}


#Test 5 Deployment pod deletion and recreation by the RC test
function t5_pod_deletion_tst(){
  
  kubectl delete pod -n testspace $($t5_pods | tail -1 | awk '{print $1}')
  echo -e "\n"
  t5_watch_deploy
  echo -e "\n"
  t5_get_deploy

}

#Test 5 deploy rescale test
function t5_deploy_rescale(){

  kubectl scale deploy deploy-test -n testspace --replicas=6
   echo -e "\n"
  t5_get_deploy
   echo -e "\n"
  t5_watch_deploy
   echo -e "\n"
  t5_get_deploy

}




} | tee -a results.txt