#!/bin/bash


kubectl delete pod image-pull-test -n testspace
kubectl delete ds -n testspace ping-daemons
kubectl delete deploy -n testspace deploy-test
kubectl delete svc -n testspace test-service
kubectl delete deploy -n testspace svc-deploy
kubectl delete pod -n testspace curl-pod
kubectl delete pod -n testspace pvc-pod
kubectl delete pvc -n testspace
kubectl delete pv -n testspace
#kubectl delete namespace testspace
