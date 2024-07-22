# Stargate Helm Chart

The Helm chart in this directory is used to deploy the Stargate service.

## Security notes

The security context of the Stargate statefulset follows the standard setup without privileged access, with the
following exceptions:

### Init container 'net-init'

This container is responsible for reconfiguring the IP tables on startup. For this, it requires the following
security context exceptions:

- NET_ADMIN linux capability for editing the IP tables and address binding
- NET_RAW linux capability for editing the IP configuration
  (`iptables -t nat -I OUTPUT -p tcp --dport 7000 -d 252.0.0.0/8 -j DNAT --to-destination :17008`)
- writable root filesystem for setting lock files during editing IP tables
- running as root for editing IP tables

### Container 'nginx'

This container serves as an egress proxy. The way its configuration works during startup, requires writable root
filesystem, and for handling child processes it requires SETUID and SETGUID capabilities:

- SETUID and SETGID linux capabilities for setting the IDs of the worker child processes
- NET_ADMIN and NET_RAW for IP tables initialization (usage reporting)
- writable root filesystem for patching /etc/nginx/nginx.conf
- running as root to be able to write to /etc/nginx

The reason for writing to /etc/nginx is that the nginx config file is edited on startup in the /etc/nginx
directory. This directory cannot be mounted from a dedicated writable volume, because it contains other files
required for nginx that are added as part of the Docker image.
