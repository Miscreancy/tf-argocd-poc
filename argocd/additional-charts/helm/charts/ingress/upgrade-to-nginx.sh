#!/usr/bin/env bash
set -euo pipefail

cluster_id=$1

cmd_proc_version=master.5367cab127d8560aafdadbad17855bb3b390faab
nginx_version=feature-CSI-3420-nginx.68ea57e5cda95ef0f5a994326c5d4e5909d1cab1

# Update cmd-proc to a version that generates hostID services
kubectl patch deployment/cmd-processor -p '{"spec":{"template":{"spec":{"$setElementOrder/containers":[{"name":"cmd-processor"}],"containers":[{"image":"registry.cloud-tools.datastax.com/cloud-ondemand/cmd-processor:'${cmd_proc_version}'","name":"cmd-processor"}]}}}}'
kubectl rollout status deployment/cmd-processor

# Reduce # of envoy pods to prevent autoscaler from creating a new node
kubectl scale --replicas=2 deployment/envoy
sleep 30

# Disconnect an envoy pod from the deployment so it persists after the deployment is removed from helm upgrade
envoy_pod=$(kubectl get pods | grep envoy | head -n1 | cut -d' ' -f1)
kubectl patch pod -p '{"metadata":{"labels":{"pod-template-hash":null},"ownerReferences":null}}' "${envoy_pod}"

# Retrieve existing ports so that the SCB does not have to be regenerated
nodeport_data=$(kubectl get service envoy-nodeports -o json)
sni_port=$(echo "${nodeport_data}" | jq '.spec.ports[] | select(.name == "cql-sni") | .nodePort')
round_robin_port=$(echo "${nodeport_data}" | jq '.spec.ports[] | select(.name == "cql-round-robin") | .nodePort')
metadata_port=$(echo "${nodeport_data}" | jq '.spec.ports[] | select(.name == "metadata-service") | .nodePort')

cat << EOF > "values.yaml"
clusterID: "${cluster_id}"
astraDatabaseVersion: "1.0.0"
nginxImage: registry.cloud-tools.datastax.com/cloud-ondemand/nginx:${nginx_version}
# Pod image
imagePullPolicy: IfNotPresent
imagePullSecrets: ""
useHostPort: true
env: dev
httpPort: 443
httpPlPort: 444
publicIPPort: 1234
cqlSNIPort: ${sni_port}
cqlSNIPrivateLinkPort: 29043
cqlRoundRobinPort: ${round_robin_port}
cqlRoundRobinPrivateLinkPort: 29045
metadataServicePort: ${metadata_port}
metadataServicePrivateLinkPort: 29081
EOF

helm upgrade --install ingress . -f values.yaml
sleep 1
kubectl rollout status daemonset/ingress
