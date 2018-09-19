#!/bin/bash

NC='\033[0m'
GREEN='\033[1;32m'
RED='\033[1;31m'
BLUE='\033[1;34m'
PRPL='\033[1;35m'

#echo -e "\n--------Test #1 - Namespace creation--------" 


function t1_namespc_crt(){

kubectl create namespace testspace 

}

# echo -e "\n--------Test #2 - Pod & image Pull--------" 


function t2_img_pull(){
cat << EOF | kubectl create -f - 
apiVersion: v1
kind: Pod
metadata:
  namespace: testspace
  name: image-pull-test
spec:
  restartPolicy: Never
  containers:
  - name: image-test
    image: busybox
    imagePullPolicy: Always
    args:
    - echo
    - "Successfully Pulled Image and Exited Container" 
EOF
}

function t2_get_pod(){
 
 timeout 10 kubectl get pod -n testspace image-pull-test --watch

}

function t2_get_logs(){
  
  kubectl logs -n testspace image-pull-test  

}

# echo -e "\n--------Test #3 - Communication Between Pods--------" 



function t3_demon_constr(){
 
 cat << EOF | kubectl create -f - 
apiVersion: apps/v1
kind: DaemonSet
metadata:
  namespace: testspace
  name: ping-daemons
  labels:
    ping: test
spec:
  selector:
    matchLabels:
      ping: pods
  template:
    metadata:
      labels:
        ping: pods
    spec:
      containers:
      - name: ping-pod
        image: busybox:1.27
        args:
        - sleep
        - "10000"
EOF
}


# sleep 60

######## Remember to put Timer

function t3_get_ping_ips() {

kubectl get po -n testspace -l ping=pods -o json | grep -i "podIP" | awk '{print $2}' | sed 's/[",]//g'

}

function t3_get_ping_pods() {

kubectl get pods -n testspace | grep ping-daemons | awk '{print $1}' 

}

function t3_ping_test(){
  
  echo -e "\n>>>>Testing connectivity from $(t3_get_ping_pods | head -1) to $(t3_get_ping_pods | tail -1)\n" 

  kubectl exec -n testspace $(t3_get_ping_pods | head -1) -it -- ping -c 4 $(t3_get_ping_ips | tail -1)  

  echo -e "\n>>>>Testing connectivity from $(t3_get_ping_pods | head -1) to $(t3_get_ping_pods | tail -1)\n" 

  kubectl exec -n testspace $(t3_get_ping_pods | tail -1) -it -- ping -c 4 $(t3_get_ping_ips | head -1) 

}

function t3_watch_pods(){

  kubectl get ds -n testspace
  timeout 20 kubectl get pods -n testspace -l ping=pods --watch

}

# echo -e "\n--------Test #4 - Public DNS Lookup--------" 

function t4_dns_tst(){
  t3_demon_constr 2>&1 /dev/null
  sleep 15
  for i in $(t3_get_ping_pods)
  do
     echo -e "\n>>>>Testing Public DNS lookup on $i\n"
     kubectl exec -n testspace $i -- nslookup google.com
  done

}

#Test 5 Deployment functions-----------------------------------------------------------------------------------------------------------------------------------------------   

# Test 5 deployment constructor
function t5_deploy_constr() {

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
  timeout 20 $t5_pods --watch
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
  labels:
    curl: pod
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

function t6_svc_watch_pods(){

  kubectl get svc -n testspace
  echo -e "\n"
  timeout 20 kubectl get pods -n testspace -l test=service,curl=pod --watch

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
  echo -e "\n${PRPL}Tunnelfront pod logs---------------------------\n$NC" 
  kubectl logs -n kube-system -l component=tunnel 

}

function t7_kubedns(){

  kubectl get deploy -n kube-system kube-dns-v20
  echo -e "\n"
  kubectl get deploy -n kube-system kube-dns-v20
  echo -e "\n"
  kubectl get pods -n kube-system -l k8s-app=kube-dns
  echo -e "${PRPL}KUBEDNS CONTAINER--------------------------------\n$NC" 
  kubectl logs -n kube-system -l k8s-app=kube-dns -c kubedns 
  echo -e "${PRPL}\nDNSMASQ CONTAINER--------------------------------\n$NC" 
  kubectl logs -n kube-system -l k8s-app=kube-dns -c dnsmasq 
  
}

function t7_etcd_health(){

  kubectl get cs etcd-0

}

#End of Test 7 -------------------------------------------------------------------------------------------------------------------------------------------------------------------

#Test 8 Storage tests ------------------------------------------------------------------------------------------------------------------------------------------------------------

function t8_get_strg_cls(){

  kubectl get sc
  echo -e "\n"
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
  labels:
    pvc: pod
spec:
  containers:
    - name: pvc-cont
      image: alpine
      args:
      - sleep
      - "1000"
      volumeMounts:
      - mountPath: "/mnt/azure"
        name: volume
  volumes:
    - name: volume
      persistentVolumeClaim:
        claimName: test-pvc
EOF

}

function t8_get_pod_pvc(){

  timeout 20 kubectl get pod -n testspace -l pvc=pod --watch

}

function t8_describe_pod(){

  kubectl describe pod -n testspace -l pvc=pod

}

### Gather Node logs ---------------------------------------------------------------------------------------------------------

t9_constructor(){

    cat << EOF | kubectl create -f - 
apiVersion: apps/v1
kind: DaemonSet
metadata:
  namespace: testspace
  name: log-demons
  labels:
    log: demon
spec:
  selector:
    matchLabels:
      log: demon
  template:
    metadata:
      labels:
        log: demon
    spec:
      volumes:
      - name: demon-volume
        hostPath:
          path: /var/log/
          type: Directory
      containers:
      - name: log-pod
        image: busybox:1.27
        volumeMounts:
        - mountPath: /demon-logs
          name: demon-volume
        args:
        - sleep
        - "10000"
EOF

}

t9_get_log_demon(){

  kubectl get pod -n testspace -l log=demon | grep log | awk {'print $1'}

}

t9_watch_demons(){

  timeout 20 kubectl get pod -n testspace -l log=demon --watch

}

t9_tar_log(){

  for i in $(t9_get_log_demon)
  do
    kubectl exec -n testspace $i -- tar cvzf /logs.tgz /demon-logs
  done

}

#/var/log/syslog var/log/azure/cluster-provision.log /var/log/cloud init-output 
function t9_get_node_logs(){

  t9_tar_log
  for i in $(t9_get_log_demon)
  do
    NODE=$(kubectl get pod -n testspace ${i} -o wide | tail -1 | awk {'print $7'})
    kubectl cp testspace/${i}:/logs.tgz $PWD/${NODE}-node-logs.tgz
  done

}

function cleanup(){

echo -e "${RED}Cleaning up Kubernetes Cluster after tests.\nThis might take a while...$NC"
kubectl delete pod image-pull-test -n testspace
kubectl delete ds -n testspace ping-daemons
kubectl delete deploy -n testspace deploy-test
kubectl delete svc -n testspace test-service
kubectl delete deploy -n testspace svc-deploy
kubectl delete pod -n testspace curl-pod
kubectl delete pod -n testspace pvc-pod
kubectl delete pvc -n testspace --all
kubectl delete pv -n testspace --all
kubectl delete namespace testspace

}
 
function print_menu(){

echo -e "\n$GREEN*************************************************************

$NC -------------------------- MENU ---------------------------

 1) Test Image pulling 
 2) Test Pod Network
 3) Test Public DNS Resolution
 4) Test Deployment Functions
 5) Test Service Functions
 6) Check Kube-System
 7) Test Persistent Storage
 8) Gather Node Logs
 9) Exit Menu

 $NC-------------------------- MENU ---------------------------

$GREEN*************************************************************\n$NC"

}

function menu_opt1(){
  
  date >> results.log
  echo -e "${BLUE}Testing Image Pull Capabilities\n$NC" | tee -a results.log
  t2_img_pull
  echo -e "\n${BLUE}Waiting for Pod to be created$NC"
  t2_get_pod
  echo -e "\n${BLUE}Gathering Logs from test$NC"
  t2_get_logs | tee -a results.log
  echo -e "\n"
  echo -e "${GREEN}Test completed, logs saved on results.log\n$NC"
  read -p "Press enter to go back to the menu..."
}

function menu_opt2(){
  
  date >> results.log
  echo -e "${BLUE}Testing Network between Pods\n$NC" | tee -a results.log
  t3_demon_constr
  echo -e "\n"
  echo -e "${BLUE}Waiting for Pods to be created on each node (20 sec)$NC"
  t3_watch_pods
  echo -e $PRPL
  t3_ping_test | tee -a results.log
  echo -e $NC
  echo -e "${GREEN}Test completed, logs saved on results.log\n$NC"
  read -p "Press enter to go back to the menu..."

}

function menu_opt3(){
 
  date >> results.log
  echo -e "${BLUE}Testing External DNS resolution from Pods\n$NC" | tee -a results.log
  echo -e "${BLUE}Waiting for Pods to be created on each node (15 seconds)$NC"
  t4_dns_tst | tee -a results.log
  echo -e "\n"
  echo -e "${GREEN}Test completed, logs saved on results.log\n$NC"
  read -p "Press enter to go back to the menu..."

}

function menu_opt4(){

  date >> results.log
  echo -e "${BLUE}Starting to test all Deployment functions\n$NC" | tee -a results.log
  t5_deploy_constr
  echo -e "${BLUE}\nWaiting for deployment to be created (20 sec)\n$NC"
  t5_watch_deploy
  echo -e "${BLUE}\nTesting image update capabilities (20 sec)\n$NC"| tee -a results.log
  t5_deploy_img_upd | tee -a results.log
  echo -e "${BLUE}\nTesting Pod failure (20 sec)\n$NC"| tee -a results.log
  t5_pod_deletion_tst | tee -a results.log
  echo -e "${BLUE}\nTesting Deployment rescale\n$NC"| tee -a results.log
  t5_deploy_rescale | tee -a results.log
  echo -e "${GREEN}Test completed, logs saved on results.log\n$NC"
  read -p "Press enter to go back to the menu..."
  
}

function menu_opt5(){

  date >> results.log
  echo -e "${BLUE}Starting to test Service Functions\n$NC" | tee -a results.log
  echo -e "${BLUE}\nWaiting for Pods and Service to be created (20 sec)\n$NC"
  t6_svc_constr
  t6_svc_pod_constr
  t6_svc_watch_pods
  echo -e "${BLUE}\nChecking Service Endpoints\n$NC" | tee -a results.log
  t6_svc_ep | tee -a results.log
  echo -e "${BLUE}\nChecking Service DNS resolution\n$NC" | tee -a results.log
  t6_svc_dns_test | tee -a results.log
  echo -e "${GREEN}Test completed, logs saved on results.log\n$NC"
  read -p "Press enter to go back to the menu..."

}

function menu_opt6(){

  date >> results.log
  echo -e "${BLUE}Collecting Kube-System Information\n$NC" | tee -a results.log
  echo -e "${BLUE}Kubernetes Nodes\n$NC"  | tee -a results.log
  t7_get_nodes  | tee -a results.log
  echo -e "${BLUE}ETCD Health\n$NC" | tee -a results.log
  t7_etcd_health | tee -a results.log
  echo -e "${BLUE}Kube-DNS logs and health status\n$NC"| tee -a results.log
  t7_kubedns | tee -a results.log
  echo -e "${BLUE}Tunnelfront Pod Health and logs \n$NC" | tee -a results.log
  t7_tunnel | tee -a results.log
  echo -e "${GREEN}Test completed, logs saved on results.log\n$NC"
  read -p "Press enter to go back to the menu..."

}

function menu_opt7(){

  date >> results.log
  echo -e "${BLUE}Starting Persistent Storage tests\n$NC" | tee -a results.log
  echo -e "${PRPL}Querying Available Storage Classes\n$NC"| tee -a results.log
  t8_get_strg_cls | tee -a results.log
  echo -e "${PRPL}\nCreating Persistent Volume (20 sec)\n$NC"
  t8_pv_constr
  sleep 20
  t8_get_pvc | tee -a results.log
  echo -e "${PRPL}\nCreating Pod with Persistent Volume Claim (20 sec)\n$NC"
  t8_pod_pvc
  echo -e "\n"
  t8_get_pod_pvc
  echo -e "${PRPL}\nPod Description$NC" | tee -a results.log
  t8_describe_pod | tee -a results.log
  echo -e "${GREEN}Test completed, logs saved on results.log\n$NC"
  read -p "Press enter to go back to the menu..." 

}

function menu_opt8(){
  echo -e "${BLUE}Creating Pods for log Gathering (25 sec)\n$NC"
  t9_constructor
  t9_watch_demons
  echo -e "${PRPL}\nGathering logs...\n$NC"
  t9_get_node_logs
  echo -e "${GREEN}\nTest completed, logs saved on $PWD\n$NC"
  read -p "Press enter to go back to the menu..."

}

function main(){

echo -e "${RED}Creating namespace for tests...$NC"
t1_namespc_crt 2>&1 /dev/null
  while true; do
    clear
    print_menu
    read -p "Please select an option: " option
    clear

    case $option in

       "1") menu_opt1;;
       "2") menu_opt2;;
       "3") menu_opt3;;
       "4") menu_opt4;;
       "5") menu_opt5;;
       "6") menu_opt6;;
       "7") menu_opt7;;
       "8") menu_opt8;;
       "9") cleanup 2> /dev/null;break;; 
       *) echo -e "${RED}You Selected an invalid option; Please try again.$NC\n";read -p "Press enter to continue...";;
   
    esac
  done
}


clear
trap ctrl_c SIGINT
function ctrl_c() {
        echo -e "$RED\nCTRL+C Detected, Starting Cluster Clean Up\n$NC"
        cleanup 2> /dev/null
        break
}

main
