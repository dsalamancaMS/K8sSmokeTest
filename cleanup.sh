#!/bin/bash


kubectl delete pod image-pull-test -n testspace
kubectl delete ds -n testspace ping-daemons
kubectl delete deploy -n testspace deploy-test
#kubectl delete namespace testspace
