---
layout: post
author: Owen Rumney
title: AWS HTTPSConnectionPool max retries exceeded
tags: [aws, awscli]
category: Amazon Web Services
---

I'm working with a new AWS account and I am moving to testing Boto3 to use the KMS service. I needed to make sure that the AWS account and secret keys were updated so ran `aws configure` to quickly update them.

I added the new keys and saw that default region was set to `[Ireland]` so accepted default and ran the following code

{% highlight python %}

import boto3

s3 = boto3.resource('s3')
for bucket in s3.buckets.all():
print(bucket.name)

{% endhighlight %}

I was puzzled to get the following error;

{% highlight python %}

botocore.vendored.requests.exceptions.ConnectionError: HTTPSConnectionPool(host='s3.ireland.amazonaws.com', port=443): Max retries exceeded with url: / (Caused by <class 'socket.gaierror'>: [Errno 8] nodename nor servname provided, or not known)

{% endhighlight %}

It didn't sit right that the url had ireland in it explicitly when its generally the region code that is used with AWS so I went back the `aws configure` and set `eu-west-1` as the default region.

On rerunning the code it all worked, so worth noting if this error comes up.
