This repository is archived, because both changes were eventually merged into upstream.
ICMP could be used via:  
```yaml
securityContext:
 sysctls:
  - name: net.ipv4.ping_group_range
    value: "0 65536"
```

# Blackbox exporter
This is fork of https://github.com/prometheus/blackbox_exporter with such changes (link to upstream):
 - [pass `server_name` as query param](#pass-server_name-as-query-param) ([#642](https://github.com/prometheus/blackbox_exporter/issues/624))
 - [non-root icmp in docker](#non-root-icmp-in-docker) ([#689](https://github.com/prometheus/blackbox_exporter/issues/689))

### Pass `server_name` as query param
In case you have to monitor many certificates installed on groups of hosts and being managed separately.
 For example multiple backends behind single Load Balancer, answering by the same name.
 
 Another use-case is monitoring HTTPS port on nodes behind Load Balancer, where certificate does not have specific node names, but only main VIP name.
 
 Right now you have to manage both `blackbox-exporter` and `prometheus` configs like this:
 
 ```yaml
# blackbox.yaml
# many sections like
   elk:
     prober: tcp
     timeout: 5s
     tcp:
       preferred_ip_protocol: ipv4
       tls: true
       tls_config:
         server_name: es.domain.local
# basically only differ in server_name
```
 
 ```yaml
# prometheus.yaml
 ...
 - job_name: blackbox
   metrics_path: /probe
   static_configs:
 # many groups like this
     - labels:
         service: elk
         __param_module: [elk]
       targets: # es.domain.local
         - es-logs-node1.domain.local:443
         - es-logs-node2.domain.local:443
         - es-logs-node3.domain.local:443
         - es-logs-node1.domain.local:9300
         - es-logs-node2.domain.local:9300
         - es-logs-node3.domain.local:9300
         - es-logs-warm-node1.domain.local:9300
 # only differ in hosts and module name
   relabel_configs:
   ...
 ```

With this `blackbox_exporter` you can have single common section on blackbox.yaml side, and only manage configs on Prometheus side: 

 ```yaml
# prometheus.yaml
 ...
 - job_name: blackbox
   metrics_path: /probe
   static_configs:
 # many groups like this
     - labels:
         service: elk
         __param_module: [elk]
         __param_server_name: [es.domain.local]
       targets: # es.domain.local
         - es-logs-node1.domain.local:443
         - es-logs-node2.domain.local:443
         - es-logs-node3.domain.local:443
         - es-logs-node1.domain.local:9300
         - es-logs-node2.domain.local:9300
         - es-logs-node3.domain.local:9300
         - es-logs-warm-node1.domain.local:9300
 # only differ in hosts and params
   relabel_configs:
   ...
 ```

### Non-root icmp in docker
You can use `icmp` module with this container and run it as non-root user.  
Docker example:
```bash
$ docker run -d -p 9115:9115 -u 65534 --cap-add=NET_RAW jetbrainsinfra/blackbox_exporter:v0.18.0
$ curl -s 'localhost:9115/probe?target=127.0.0.1&module=icmp&debug=true'
```
Kubernetes example:
```yaml
  securityContext:
    allowPrivilegeEscalation: true
    capabilities:
      add:
        - NET_RAW
```

### Usage
Docker images are available on [Docker Hub](https://hub.docker.com/repository/docker/jetbrainsinfra/blackbox_exporter/tags?page=1):  
`jetbrainsinfra/blackbox_exporter`

### Build
```
~/go/bin/promu crossbuild
make docker
docker tag jetbrainsinfra/blackbox-exporter-linux-amd64:master jetbrainsinfra/blackbox_exporter:v0.18.0
docker push jetbrainsinfra/blackbox_exporter:v0.18.0
```
