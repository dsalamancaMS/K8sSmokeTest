#!/bin/bash

kubectl delete namespace testspace
kubectl delete pod image-pull-test -n testspace