# Ingress Charts

This chart contains the deployment configuration for the ingress daemonset in the Astra Classic clusters.

## Security exceptions

The container security configuration of the ingress daemonset requires the following exceptions from the
standard non-permissive container security configuration, in order to be able to reconfigure iptables:

### Init container 'init'

- run as root user
- NET_ADMIN linux capability
- NET_RAW linux capability
- writable root filesystem (for setting lock in /run)
