---
layout: post
title: "Using the AWS waiter"
date: 2020-02-19 17:05:15
image: "/assets/img/"
description: Using the waiter to wait for something to happen in your lambda
tags: [aws, python, lambda]
categories:
twitter_text: Using the waiter in your AWS lambda
---

The AWS SDK provides a number of `waiters` that allow you to block your code while waiting for a process to complete. One that we make use of in our managed ECS container rollout is the `services_stable` waiter. This will wait for a defined amount of time for an ECS service to become stable, or raise an exception.

```python
# bring in the boto3 import
import boto3
import botocore

# create a session object
session = boto3.session.Session()

# create an ECS client
ecs = session.client('ecs')

# trigger an update to the service
ecs.update_service(cluster='myCluster',
									 service='myService',
                   taskDefinition='myServiceTaskDefinition:10')

# create a waiter
waiter = ecs.get_waiter('services_stable')

try:
	logger.info('waiting for myService to become stable')

	# call the wait method passing in an array of services you want to wait for
	waiter.wait(cluster='myCluster', services=['myService'])

except botocore.exceptions.WaitError as wex:
	logger.error('The service 'myService' didn't become stable. {}'.format(wex))
```

The Boto3 documentation has the available waiters for each service that supports them, for example the `ecs` waiters [can be found here](https://boto3.amazonaws.com/v1/documentation/api/1.9.42/reference/services/ecs.html#waiters).{:target="\_blank"}

By default, the `ServicesStable` waiter will check every 15 seconds for 40 attempts. You can pass overrides into the wait call if required;

```python
waiter.wait(cluster_name='myCluster',
						services=['myService'],
					  WaiterConfig={'Delay': 30, 'MaxAttempts': 10})
```

This will wait for 5 minutes (300 seconds) for the service to become stable before throwing a `botocore.exceptions.WaitError` if not successful.

If you're waiting for a large number of services, its worth noting that you can only pass 10 services at a time, so you'll need to chunk them.
