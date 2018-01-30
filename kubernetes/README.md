# Deploy in IBM Cloud Kubernetes

## Create Namespace and certificates

```
kubectl create namespace gameon-system

openssl req -x509 -newkey rsa:4096 -keyout ./onlykey.pem -out ./onlycert.pem -days 365 -nodes
cat ./onlycert.pem ./onlykey.pem > ./cert.pem
rm ./onlycert.pem ./onlykey.pem
kubectl create secret generic --namespace=gameon-system --from-file=./cert.pem global-cert
```

## Modify ingress.yaml and gameon-configmap.yaml

* Get **Ingress subdomain** and **Ingress secret**

```
bx cs cluster-get <your-cluster-name>
```

You should get something like this:

<pre>
Retrieving cluster anthony-test...
OK

Name:			anthony-test
ID:			bbdb1ff6a36846e9b2dfb522a07005af
State:			normal
Created:		2017-10-09T21:43:56+0000
Datacenter:		dal10
Master URL:		https://qq.ww.ee.rr:qwer
<b>Ingress subdomain:	anthony-test.us-south.containers.mybluemix.net
Ingress secret:		anthony-test</b>
Workers:		2
Version:		1.7.4_1506* (1.8.6_1504 latest)
</pre>

* Add them in ingress.yaml

<pre>
...
tls:
    - hosts:
      <b>- anthony-test.us-south.containers.mybluemix.net # Replace value with your own
      secretName: anthony-test # Add this line and replace value with your own</b>
  rules:
  - host: <b>anthony-test.us-south.containers.mybluemix.net # Replace value with your own</b>
...
</pre>

* Modify configmap.yaml

Replace their values with your own

<pre>
FRONT_END_PLAYER_URL: <b>http://anthony-test.us-south.containers.mybluemix.net/players/v1/accounts</b>
FRONT_END_SUCCESS_CALLBACK: <b>http://anthony-test.us-south.containers.mybluemix.net/#/login/callback</b>
FRONT_END_FAIL_CALLBACK: <b>http://anthony-test.us-south.containers.mybluemix.net/#/game</b>
FRONT_END_AUTH_URL: <b>http://anthony-test.us-south.containers.mybluemix.net/auth</b>
</pre>

## Create Kubernetes resources

```
kubectl apply -f kubernetes/ingress.yaml

kubectl apply -f kubernetes/gameon-configmap.yaml 

kubectl apply -f kubernetes/couchdb.yaml
kubectl apply -f kubernetes/kafka.yaml

kubectl apply -f kubernetes/auth.yaml
kubectl apply -f kubernetes/mediator.yaml
kubectl apply -f kubernetes/map.yaml
kubectl apply -f kubernetes/player.yaml
kubectl apply -f kubernetes/room.yaml
kubectl apply -f kubernetes/webapp.yaml
```

## Delete Kubernetes Resources

```
kubectl delete -f kubernetes/ingress.yaml

kubectl delete -f kubernetes/gameon-configmap.yaml 

kubectl delete -f kubernetes/couchdb.yaml
kubectl delete -f kubernetes/kafka.yaml

kubectl delete -f kubernetes/auth.yaml
kubectl delete -f kubernetes/mediator.yaml
kubectl delete -f kubernetes/map.yaml
kubectl delete -f kubernetes/player.yaml
kubectl delete -f kubernetes/room.yaml
kubectl delete -f kubernetes/webapp.yaml

kubectl delete secret global-cert -n gameon-system
```
