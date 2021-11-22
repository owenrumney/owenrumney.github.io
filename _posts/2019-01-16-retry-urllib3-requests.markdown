---
layout: post
author: Owen Rumney
title: Adding retry logic to urllib3 Python code
description: Tutorial on the steps required to add retry logic to urllib3 requests
tags: [python, urllib3, retry logic]
categories: [Programming]
---

In this post I'm going to cover the basics of implementing retry logic using urllib3.

There is probably a solid argument saying "why aren't you just using [requests](http://docs.python-requests.org/en/master/)?", as it happens, requests uses urllib3 and it's Retry functionality.


For the purposes of this post, lets imagine that we have a REST service and one of the resources is particularly popular, or flakey, and is throwing the occasional [503 HTTP Code](https://httpstatuses.com/503). 

Our initial code might look something like;

```python
import urllib3

http = urllib3.PoolManager()
r = http.request('GET', 'http://www.myflakyendpoint.com/dicey')
if r.status == 200:
    logger.info('That was lucky')
```

We have once chance to get it right. Yes, some convoluted while loop against the status code could be used, but thats ugly.

Another option available to us is to make use of `urllib3.util.Retry` and get our request to retry a specified amount of times.

```python
import urllib3
from urllib3.util import Retry
from urllib3.exceptions import MaxRetryError

http = urllib3.PoolManager()
retry = Retry(3, raise_on_status=True, status_forcelist=range(500, 600))

try:
    r = http.request('GET', 'http://www.myflakyendpoint.com/dicey', retries=retry)
except MaxRetryError as m_err:
    logger.error('Failed due to {}'.format(m_err.reason))
```

In this code we've created a `Retry` object telling it to retry a total of 3 times and throw an exception if all retries are exhausted. The `status_forcelist` is the HTTP status codes that will be considered to be failures.

Some other interesting arguments for the `Retry` object are.

|Argument  |Comment |
|:---|:---|
|  total | The total number of retries that are allowed. Trumps the combined figure of connect and read   |
| read  | How many read retries that are allowed   |
| connect  | How many connect errors that are allowed  |
| redirect | How many redirects to allow. This is handy to prevent redirect loops |
| method_whitelist | Which pethos are allowed. By default only idempotent methods are allowed, ruling out POST |
|backoff_factor | How much to increase the back off factor (see docs for more info)|
| raise_on_status | Whether to return the failed status or raise an exception |

For more information, see the [urllib3 documentation](https://urllib3.readthedocs.io/en/latest/reference/urllib3.util.html#module-urllib3.util.retry)

