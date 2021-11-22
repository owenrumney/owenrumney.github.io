---
layout: post
author: Owen Rumney
title: Allow connection to dockerised elasticsearch other than localhost
tags: [docker, elasticsearch, kubernetes, minikube]
---

We need to access ElasticSearch in a namespace within minikube and the other Pods can't connect to 9200. It turns out that from the box its limited to localhost and the `network.host` property needs updating.

Setting `network.host` in the `elasticsearch.yml` configuration file on a docker container will put the instance into "Production" mode which will invoke a load of limit checks including, but not limited to the number of threads allocated for a user.

To my knowledge setting `ulimit`s in Docker isn't trivial so another way to expose ElasticSearch to other pods is required.

The answer appears to be, set `http.host: 0.0.0.0` so that its listening on all interfaces. This will allow you to stay as a development instance without all the ulimit issues stopping startup and you can access outside of the Pod.
