#!/bin/bash
{
NC='\033[0m'
GREEN='\033[1;32m'
RED='\033[1;31m'
BLUE='\033[1;34m'
PRPL='\033[1;35m'

> results.txt
# echo -e '-------------------- Testing Kube Components --------------------'


# date >> results.txt

# echo -e "\n--------Test #1 - Namespace creation--------" 

# echo -e "\n >>>>>>>>>> Creating Namespace"

# kubectl create namespace testspace 

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

echo -e "\n--------Test #4 - Public DNS Lookup--------" 

for i in $(get_ping_pods)
do
    echo -e "\n>>>>Testing Public DNS lookup on $i\n"
    kubectl exec -n testspace $i -- nslookup google.com
done



} | tee -a results.txt