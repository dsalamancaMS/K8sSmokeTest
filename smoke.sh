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

function namespace_create(){

kubectl create namespace testspace 

}

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



#Test 5 Deployment functions-----------------------------------------------------------------------------------------------------------------------------------------------   

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

#End of Test 5---------------------------------------------------------------------------------------------------------------------------------------------------------------

#Test 6 Services functions---------------------------------------------------------------------------------------------------------------------------------------------------

function t6_svc_constr(){

  cat << EOF | kubectl create -f -
kind: Service
apiVersion: v1
metadata:
  namespace: testspace
  name: test-service
spec:
  selector:
    test: service
  ports:
  - protocol: TCP
    port: 80
EOF

}

function t6_svc_ep(){
 
  kubectl get ep test-service -n testspace 
  echo -e "\n"
  kubectl get ep test-service -n testspace -o yaml

}

function t6_svc_pod_constr(){

  cat << EOF | kubectl create -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: testspace
  name: svc-deploy
  labels:
    test: service
spec:
  replicas: 3
  selector:
    matchLabels:
      test: service
  template:
    metadata:
      labels:
        test: service
    spec:
      containers:
      - name: svc-test-pods
        image: httpd
        ports:
        - containerPort: 80
EOF

cat << EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  namespace: testspace
  name: curl-pod
spec:
  restartPolicy: Never
  containers:
  - name: image-test
    image: dsalamanca/netshell
    imagePullPolicy: Always
    args:
    - sleep
    - "1000" 

EOF

}

function t6_svc_dns_test(){

kubectl exec -n testspace curl-pod -- curl -v test-service

}

#End of Test 6 ---------------------------------------------------------------------------------------------------------------------------------------------------------------

#Test 7 Kube-system Status------------------------------------------------------------------------------------------------------------------------------------------------

function t7_get_nodes(){

  kubectl get nodes -o wide
  echo -e "\n"
  kubectl get nodes -o yaml
}

function t7_tunnel(){

  kubectl get deploy -n kube-system tunnelfront
  echo -e "-n"
  kubectl describe pod -n kube-system -l component=tunnel
  kubectl logs -n kube-system -l component=tunnel > tunnel.log
  echo -e "\nTunnelfront pod logs have been saved under tunnel.log"
}

function t7_kubedns(){

  kubectl get deploy -n kube-system kube-dns-v20
  echo -e "\n"
  kubectl get deploy -n kube-system kube-dns-v20
  echo -e "\n"
  kubectl get pods -n kube-system -l k8s-app=kube-dns
  echo -e "KUBEDNS CONTAINER--------------------------------\n" > kube-dns.log
  kubectl logs -n kube-system -l k8s-app=kube-dns -c kubedns >> kube-dns.log
  echo -e "\nDNSMASQ CONTAINER--------------------------------\n" >> kube-dns.log
  kubectl logs -n kube-system -l k8s-app=kube-dns -c dnsmasq >> kube-dns.log
  echo -e "\nkube-dns Logs saved under kube-dns.log"
  
}

function t7_etcd_health(){

  kubectl get cs etcd-0

}

#End of Test 7 -------------------------------------------------------------------------------------------------------------------------------------------------------------------

#Test 8 Storage tests ------------------------------------------------------------------------------------------------------------------------------------------------------------

function t8_get_strg_cls(){

  kubectl describe sc 

}

function t8_pv_constr(){

  cat << EOF | kubectl create -f - 
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  namespace: testspace
  name: test-pvc
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: managed-premium
  resources:
    requests:
      storage: 5Gi
EOF

}

function t8_get_pvc(){

  echo -e "Persistent Volume\n"
  kubectl get pv -n testspace
  echo -e "\n"
  kubectl describe pv -n testspace 
  echo -e "Persistent Volume Claim:\n"
  kubectl get pvc -n testspace
  echo -e "\n"
  kubectl describe pvc -n testspace

}


function t8_pod_pvc(){

  cat << EOF | kubectl create -f -
kind: Pod
apiVersion: v1
metadata:
  namespace: testspace
  name: pvc-pod
spec:
  containers:
    - name: pvc-cont
      image: alpine
      volumeMounts:
      - mountPath: "/mnt/azure"
        name: volume
  volumes:
    - name: volume
      persistentVolumeClaim:
        claimName: test-pvc
EOF

}

} | tee -a results.txt