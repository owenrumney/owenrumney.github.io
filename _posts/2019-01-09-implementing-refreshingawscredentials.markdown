---
layout: post
author: Owen Rumney
title: RefreshingAWSCredentials with .NET
description: Steps required to handle refreshing AWS credentials when using the AWS .NET SDK
tags: [aws, c#, csharp, .net aws sdk]
categories: [Amazon Web Services, Programming]
---

Where I am currently working we have Single Sign On for AWS API calls and need to use task accounts to connect and get temporary credentials. To that end, its not very easy to have long running processes making calls to AWS API's such as S3 and SQS.

I am working a proof of concept which has a 3rd party .NET component which listens to SQS messages, calls into a proprietary API then dumps the results on S3. This code wasn't written by people who knew about the hoops we need to authenticate.

To complicate things, the context the application runs under isn't the context of the service account which has been granted rights to the appropriate role and the instance profile doesn't have the correct rights. (For reasons I won't go into, the Ops team won't correct this).

So, having written that, I realise we're looking at a very niche use case, but if it looks familiar, read on.

## Solution

Behind the scenes, there is a PowerShell in the background running as a scheduled task to go through Single Sign On and get new tokens to write in the credential file. I won't go into any more detail than that as its very company specific.

As the 3rd party application creates the client on startup it uses the latest credentials but they don't get refreshed from the credential file. I found an abstract class in the .NET SDK called `RefreshingAWSCredentials` which looked promising.

With this class, you can set an expiration for the Credential object such that any AWS SDK client that is using it for the API calls - for example;

```csharp
var s3Client = new AmazonS3Client(ExternalRefreshingAWSCredentilas.Credentials);
```

will create an S3Client that is given the refreshing credentials specified below.

```csharp
using Amazon.Runtime;
using Amazon.Runtime.CredentialManagement;
using log4net;
using System;
using System.Configuration;

namespace AwsCredentialsExample.Credentials
{
    public class ExternalRefreshingAWSCredentials : RefreshingAWSCredentials
    {
        private static readonly object lockObj = new Object();
        private static readonly ILog Logger = LogManager.GetLogger(typeof(ExternalRefreshingAWSCredentials));
        private readonly string credentialFileProfile;
        private readonly string credentialFileLocation;
        private static ExternalRefreshingAWSCredentials refreshingCredentials;
        private CredentialsRefreshState credentialRefreshState;
        private int refreshMinutes = 45;

        public static ExternalRefreshingAWSCredentials Credentials {
            get {
                if (refreshingCredentials == null) {
                    lock (lockObj) {
                        if (refreshingCredentials == null) {
                            refreshingCredentials = new ExternalRefreshingAWSCredentials();
                        }
                    }
                }
                return refreshingCredentials;
            }
        }

        private ExternalRefreshingAWSCredentials()
        {
             credentialFileProfile = ConfigurationManager.AppSettings["CredentialFileProfile"];
             credentialFileLocation = ConfigurationManager.AppSettings["CredentialFileLocation"];
             if (ConfigurationManager.AppSettings.HasKey("ClientRefreshIntervalMinutes"))
             {
                 refreshMinutes = int.Parse(ConfigurationManager.AppSettings.Get("ClientRefreshIntervalMinutes"));
             }
             Logger.Info(string.Format("Credential file location is {0}", credentialFileLocation));
              Logger.Info(string.Format("Credential file profile is {0}", credentialFileProfile));
            credentialRefreshState = GenerateNewCredentials();
        }

        public override void ClearCredentials()
        {
            Logger.Info("Clearing the credentials");
            credentialRefreshState = null;
        }

        protected override CredentialsRefreshState GenerateNewCredentials()
        {
            Logger.Info(string.Format("Generating credentials, valid for {0} minutes", refreshMinutes));
            var credFile = new StoredProfileAWSCredentials(credentialFileProfile, credentialFileLocation);
            return new CredentialsRefreshState(credFile.GetCredentials(), DateTime.Now.AddMinutes(refreshMinutes));
        }

        public override ImmutableCredentials GetCredentials()
        {
            if (credentialRefreshState == null || credentialRefreshState.Expiration < DateTime.Now)
            {
                credentialRefreshState = GenerateNewCredentials();
            }
            return credentialRefreshState.Credentials;
        }
    }
}

```

## Usage

There are three configurations to be used with this. These should be added as AppSettings in the app.config

1. `CredentialFileLocation` - The location of the credential file that is being updated externally (in this case by PowerShell)
2. `CredentialFileProfile` - The profile from the credential file to use
3. `ClientRefreshIntervalMinutes` - How long to keep the credentials before expiring them (defaults to 45 minutes)

As suggested before, you can now create your AWS clients passing in the `Credentials` property in place of any of the normally used `Credentials` objects.

```csharp
var s3Client = new AmazonS3Client(ExternalRefreshingAWSCredentials.Credentials);
```
