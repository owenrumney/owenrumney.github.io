---
layout: post
title: Moving AWS Diagrams, aka Docker for cheapskates
description: Fargate with an ALB started to get a bit expensive so I needed to find a new way to host my aws diagram tool.
tags: [aws, docker, diagrams, nginx, letsencrypt]
categories: [Amazon Web Services]
---

Last year I created a diagram tool specifically for AWS diagrams. It was essentially a hack of the underlying code draw.io uses.

The reality is, if you're going to be doing diagrams you might as well use the proper draw.io app but I wanted to provide a way that didn't need signup or any personal data being handed over. (I did add analytics so I could see if it was being used).

## The Setup

I have been running the application (Java and HTML/JS/CSS) as a Docker container in Amazon Fargate for the past 6 months or so, this was with a Amazon Application Load Balancer sitting infront providing an HTTP endpoint. I got a load of AWS credits around the same time, so money was no object.

## The Now Setup

Fast forward to 2020 and my credits have all gone/expired so I am footing the bill for the ALB and the Fargate usage. The docker container doesn't cost too much but the ALB is expensive enough to want to find an alternative to not kill off the project

## The Solution

Bearing in mind I have a Dockerfile already created and a dockerhub account, I decided the best way was going to be find a cheap and cheerful box to run docker on and expose the service using Nginx sitting alongside.

While looking into this, I discovered I can run a DigitalOcean droplet for \$5/month - given the amount of traffic I'm getting, the one droplet will do for now. I can review if need be in the future.

I also discovered that while I planned to use nginx, [Jason Wilder](https://github.com/jwilder/nginx-proxy) has created an automated image which used docker-gen to grab starting containers and add them to the nginx config automagically.

The last thing I wanted was to be able to get SSL/TLS certificate through Letsencrypt - here I used the letsencrypt companion from [JrCs](https://github.com/JrCs/docker-letsencrypt-nginx-proxy-companion)

### Digital Ocean Droplet

The droplet is a cheap and cheerful Ubuntu instance that I installed docker and docker compose onto. I'll cover that in a separate post.

The droplet has a Firewall assigned which is allowing port 80 and 443 traffic, but nothing else.

### Nginx Docker Compose

I am using Docker Compose to create the containers on the box so I need a docker compose file for nginx and lets encrypt companion.

```ruby
version: '2'

services:
  nginx-proxy:
    restart: always
    image: jwilder/nginx-proxy
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - "/etc/nginx/vhost.d"
      - "/usr/share/nginx/html"
      - "/var/run/docker.sock:/tmp/docker.sock:ro"
      - "/etc/nginx/certs"

  letsencrypt-nginx-proxy-companion:
    restart: always
    image: jrcs/letsencrypt-nginx-proxy-companion
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
    volumes_from:
      - "nginx-proxy"
```

This creates the services for the reverse proxy and letsencrypt companion. The mounted Docker socket allows the instances to see new containers start and the shared volumes allow for the lets encrypt container to create files for the nginx-proxy to consume.

### Nginx for AWS Backend

AWS Backend is the name I gave the backend for the AWS diagram tool. In hindsight, it sounds a lot loftier a name that it actually does.

The solution is comprised of a `jar` and some html. The docker file is fairly basic too

```docker
FROM amazoncorretto:8
# copy WAR into image
COPY www /editor
COPY index.html /index.html
COPY jars/mxPdf.jar /mxPdf.jar
COPY backend/target/backend-1.0-SNAPSHOT-jar-with-dependencies.jar /backend.jar

# expose port of the container
EXPOSE 8080

# run application with this command line
CMD ["/usr/bin/java", "-jar", "backend.jar", "-cp", "/*"]
```

To build this locally;

1. Login to Docker

```shell
docker login -u owenrumney`
```

2. Build the image

```shell
docker build -t owenrumney/awsbackend .
```

3. Push to `Dockerhub`

```shell
docker push owenrumney/awsbackend
```

Now the image is available for use, I can add another compose file.

```ruby
version: '2'

services:
  awsbackend:
    restart: always
    image: owenrumney/awsbackend:latest
    environment:
      - VIRTUAL_HOST=www.awsdiagrams.io
      - VIRTUAL_PORT=8080
      - LETSENCRYPT_HOST=www.awsdiagrams.io
```

The environment variables are uses by the proxy and the companion to create the certs and to configure the nginx routing.

You can see the finished result running at [AWS Diagrams](https://www.awsdiagrams.io/editor)
