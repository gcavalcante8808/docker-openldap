#!/bin/bash

for i in *.yaml; do
    kubectl delete -f $i;
done
