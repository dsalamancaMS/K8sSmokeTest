#!/bin/bash

> results.txt
echo -e '-------------------- Testing Kube Components --------------------'


date >> results.txt

echo -e "\nTest #1 - Namespace creation" |& tee -a results.txt

echo -e "\n >>>>>>>>>> Creating Namespace"

kubectl create namespace testspace |& tee -a results.txt

echo -e "\nTest #2 - Pod & image Pull" |& tee -a results.txt

echo -e '\n >>>>>>>>>> Pulling Image and Creating Pod'

cat << EOF | kubectl create -f - |& tee -a results.txt
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
    - "success" 
EOF


echo -e "\nTest #3 - Communication Between Pods" |& tee -a results.txt

echo -e "\n >>>>>>>>>> Creating Pods for Test"

cat << EOF | kubectl create -f - |& tee -a results.txt
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
        image: busybox
        args:
        - sleep
        - "240"
EOF

kubectl get pods -n testspace | grep ping-daemons | awk '{print $1}'