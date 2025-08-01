follow instructions as per https://docs.k3s.io/quick-start

```
curl -sfL https://get.k3s.io | sh -
``` 

on master

and then

```
curl -sfL https://get.k3s.io | K3S_URL=https://myserver:6443 K3S_TOKEN=mynodetoken sh -
```

on agents

you can find the data in
/etc/rancher/k3s/k3s.yaml 
/var/lib/rancher/k3s/server/node-token

