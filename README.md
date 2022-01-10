[[_TOC_]]


# FELFEL
--------------------------------

This app is a flask api which shows a counter from redis and store it in the redis cluster.

# Requirements
--------------------------------

- Docker 20.x
- Docker-compose 3
- Minikube
- Helm 3

# Usage

To run this chart you need to verify if your minikube is running and it has the nginx ingress controller enabled. Otherwise you can run this command `minikube addons enable ingress`

```bash
git clone https://github.com/amine7777/felfel
cd felfel

export REDIS_PASSWORD=<your-password>

chmod 700 deploy_felfel.sh
./deploy_felfel.sh
```

Before you run the script please take a look on the variables inside the script.


# Step 1

The first step was to run the flask api without any error. I have create a local redis server and I just executed `python3 app.py`

I found out that the flask api is not working due to an integer variable but python requires a string instead. This is how I changed the code. 

#### old code
```python
key = 'HIT_COUNT'
count = int(client.get(key)) or 0
response = f'Hello FELFEL. The count is: {count}'
client.set(key, count + 1)
```
#### new code

```python
key = 'HIT_COUNT'
count = client.incr('hits')
print(count)
response = f'Hello FELFEL. The count is: {count}'
client.set(key, count)
```
# Step 2

Create a lightweight Dockerfile
I have used an alpine to have the minimum size

```Dockerfile
FROM alpine:latest

RUN apk update
RUN apk add py-pip
RUN apk add --no-cache python3-dev 
RUN pip install --upgrade pip

WORKDIR /app
COPY . /app
RUN pip --no-cache-dir install -r requirements.txt

CMD ["python3", "app.py"]
```


# Step 3

Once we have created the Dockerfile of the flask api.
The docker compose part is very easy.
We just have to create 2 services one for the app the second for the redis database

```Docekrfile
version: '3'
services:
  web:
    build: .
    ports:
     - "8080:8080"
    volumes:
     - .:/code
    environment:
      REDIS_USERNAME: ''
      REDIS_PASSWORD: "mypasswordd"
      REDIS_HOST: redis
      REDIS_PORT: 6379
      REDIS_DB: 0
    depends_on:
     - redis
  redis:
    image: redis
    command: >
      --requirepass "mypasswordd"
```

> Of course the docker-compose is only for testing we should not display the passwords
We should use at least environment variables.

# Step 4

In this step I have directly created a helm chart using this command `helm create myfelfel`
this will help out to avoid all the templating in helm. I can have the minimum resources to deploy on minikube.

I have added the redis [chart](https://artifacthub.io/packages/helm/bitnami/redis) as dependency for the app helm chart. I have added some environment variables in order to let the app reach the Redis master internal dns. Once the resources were deployed it was the time to change the service type of the app and set up the ingress. 

Then when the ingress is created. we just have to add the ip of the ingress which is the same as the internal ip of the node and the host name to the /etc/hosts.

After this we can just run `curl hostname`

# Step 5

I have added a ci yaml file wich test the deployment in containerized minikube.
The ci could drop an error but as soon as you have the curl command responding 200 code then the app is working.
