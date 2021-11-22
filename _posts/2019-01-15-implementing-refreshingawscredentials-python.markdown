---
layout: post
author: Owen Rumney
title: Refreshing AWS credentials in Python
description: Handling refreshing credentials in python code using boto3 and botocore
tags: [aws, python, botocore, boto3]
category: Amazon Web Services
categories: [Amazon Web Services, Programming]
---

In a recent post I covered an [using RefreshingAWSCredentials within .NET AWS SDK]({% post_url  2019-01-09-implementing-refreshingawscredentials %}) to solve an issue with the way my current organisation has configured SingleSignOn (SSO) and temporary credentials.

Essentially, the solution involves a background process updating a credenial file then using a time limited `AWSCredential` object to refresh the credentials.

## Next...

The next issue to surface was satisfying the same requirement but for the Python based component of the 3rd party solution.

## Refreshing Credential File

In this case, on RedHat instance, there is a cron job executing a Python script which handles the SSO process and writes the updated credentials and session token to a file which can be used by the 3rd party component.

## Refreshing the Credentials in code

The exising code creates a session then creates the required resources. This works fine for the first hour till the temporary credentials expire.

```python
from botocore.session import get_session

queues['incoming'] = session.resource('sqs', region).get_queue_by_name(QueueName='incoming_queue')
```

There is only a small amount of work to make this refreshing against the externally updated credential file. For this we'll make use of the `RefreshableCredentials` from `botocore.credentials`.

```python
from botocore.credentials import RefreshableCredentials
from botocore.session import get_session
from configparser import ConfigParser
from datetime import datetime, timedelta, timezone

def refresh_external_credentials():
    config = ConfigParser()
    config.read(credential_file_path)
    profile = config.get(profile_name)
    expiry = (datetime.now(timezone.utc) + timedelta(minutes=refresh_minutes))
    return {
        "access_key": profile.get('aws_access_key_id'),
        "secret_key": profile.get('aws_secret_access_key'),
        "token": profile.get('aws_session_token'),
        "expiry_time": expiry.isoformat()
    }
```

There are a few config entries here.

- `credential_file_path` is the location of the credential file that is getting externally updated
- `profile_name` is the profile in the credential file that you want to use
- `refresh_minutes` is the time before the AWS credential will expire and the `refresh_external_credentials()` function will get called.

We now need to create the credential object for a session which will then be able to auto refresh.

```python
session_credentials = RefreshableCredentials.create_from_metadata(
    metadata = refresh_external_credentials(),
    refresh_using = refresh_external_credentials,
    method = 'sts-assume-role'
)
```

Going back to the original code, the new `session_credentials` can be plugged in to provide long life application against temporary tokens.

```python
import boto3

# ideally taken from config
region = 'eu-west-1'
incoming_queue_name = 'incoming_queue'

session = get_session()
session._credentials = session_credentials
autorefresh_session = boto3.Session(botocore_session=session)

queues['incoming'] = autorefresh_session.resource('sqs', region).get_queue_by_name(QueueName=incoming_queue_name)

```
