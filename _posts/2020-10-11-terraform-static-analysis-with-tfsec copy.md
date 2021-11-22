---
layout: post
title: "Terraform Static Analysis with tfsec"
date: 2020-10-11 00:00:00
image: '/assets/img/blog-author.png'
description: Security based static analysis for Terraform using tfsec
tags: [tfsec, terraform, security, static-analysis]
categories:
twitter_text: Security based static analysis for Terraform using tfsec
---

We use [Terraform](https://www.terraform.io) for all our deployment automation needs. Thanks to it's fantastic extensibility, if there isn't a provider available to do what we need, it's very easy to create one.

Terraform, for those who haven't used it before, lets you declaratively specify the resources that you want to deploy and then maintains a state of what has and hasn't been deployed. For deployed resources, it tracks the characteristics or attributes, and updates accordingly with updates.

As an example, say we wanted to create a new S3 bucket in our AWS account we might define something like;

```terraform
resource "aws_s3_bucket" "my-bucket-for-secret-things" {
  bucket = "my-bucket-for-secret-things"
  acl    = "public-read"

  tags = {
    Name        = "Sensitive Storage Bucket"
    Environment = "Production"
  }
}
```

Now, you might see straight away that there is a potential issue here - the bucket has an ACL allowing `public-read`. Checking the [AWS Documentation](https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html#canned-acl) on canned responses, shows us that public read has the following permissions;
```
Owner gets FULL_CONTROL. The AllUsers group (see Who Is a Grantee?) gets READ access.
```

We can see this easily with a single resource in our file, but imagine this was just one resource among thousands in a project; this could very easily go unnoticed and end up in production with a wide open bucket.

## Enter TFSEC

`tfsec` is a static analysis tool for Terraform created by [liamg](https://www.github.com/liamg). It will tell you if there are security issues in your Terraform. Installation is simple;

### Mac

`tfsec` is available for install with homebrew
```
brew install tfsec
```

### Windows
`tfsec` is available for install with Chocolatey
```
choco install tfsec
```

### Linux/everything else
Alternatively, you can install using `go get` 
```shell
go get -u github.com/tfsec/tfsec/cmd/tfsec
```

We can use `tfsec` to test our Terraform by simply running the command against the folder with our terraform in it.
```
.
|_ tf/
    |_ main.tf
```

Assuming that the above resource for the S3 bucket is in `main.tf`, we can run 

```
tfsec tf
```

This will give me a list of problems categorised into severities. 

```terraform
3 potential problems detected:

Problem 1

  [AWS001][WARNING] Resource 'aws_s3_bucket.my-bucket-for-secret-things' has an ACL which allows public read access.
  /tmp/tfsec/main.tf:5

       2 | 
       3 | resource "aws_s3_bucket" "my-bucket-for-secret-things" {
       4 |   bucket = "my-bucket-for-secret-things"
       5 |   acl    = "public-read"
       6 | 
       7 |   tags = {
       8 |     Name        = "Sensitive Storage Bucket"

  See https://github.com/tfsec/tfsec/wiki/AWS001 for more information.

Problem 2

  [AWS002][ERROR] Resource 'aws_s3_bucket.my-bucket-for-secret-things' does not have logging enabled.
  /tmp/tfsec/main.tf:3-11

       1 | 
       2 | 
       3 | resource "aws_s3_bucket" "my-bucket-for-secret-things" {
       4 |   bucket = "my-bucket-for-secret-things"
       5 |   acl    = "public-read"
       6 | 
       7 |   tags = {
       8 |     Name        = "Sensitive Storage Bucket"
       9 |     Environment = "Production"
      10 |   }
      11 | }
      12 | 

  See https://github.com/tfsec/tfsec/wiki/AWS002 for more information.

Problem 3

  [AWS017][ERROR] Resource 'aws_s3_bucket.my-bucket-for-secret-things' defines an un-encrypted S3 bucket (missing server_side_encryption_configuration block).
  /tmp/tfsec/main.tf:3-11

       1 | 
       2 | 
       3 | resource "aws_s3_bucket" "my-bucket-for-secret-things" {
       4 |   bucket = "my-bucket-for-secret-things"
       5 |   acl    = "public-read"
       6 | 
       7 |   tags = {
       8 |     Name        = "Sensitive Storage Bucket"
       9 |     Environment = "Production"
      10 |   }
      11 | }
      12 | 

  See https://github.com/tfsec/tfsec/wiki/AWS017 for more information.

```

We can see that it has identified that we have a public acl specified, this is a warning to draw our attention to the fact and allow us to make a judgement call.

The other two errors tell us that we don't have "at rest" encryption and we could do with access logging. All in all very useful since I'd forgotten them.

### But there is more

One of the benefits of `tfsec` is the ability for it to process default variable values and report on them as well. For example if we had a variable for the acl.

```terraform
variable "bucket-acl" {
    description = "The ACL for S3 buckets"
    default     = "public-read"
}
```

then we update the `main.tf` file to use this variable rather than the hard coded value;

```terraform
resource "aws_s3_bucket" "my-bucket-for-secret-things" {
  bucket = "my-bucket-for-secret-things"
  acl    = var.bucket-acl

  tags = {
    Name        = "Sensitive Storage Bucket"
    Environment = "Production"
  }
}
```

Our folder structure now looks more like this;
```
.
|_ tf/
    |_ main.tf
    |_ variables.tf
```

Now when we run `tfsec` against the `tf` folder it gives us a slightly different error;
```terraform
Problem 1

  [AWS001][] Resource 'aws_s3_bucket.my-bucket-for-secret-things' has an ACL which allows public read access.
  /tmp/tfsec/main.tf:5

       2 | 
       3 | resource "aws_s3_bucket" "my-bucket-for-secret-things" {
       4 |   bucket = "my-bucket-for-secret-things"
       5 |   acl    = var.bucket-acl    [string] "public-read"
       6 | 
       7 |   tags = {
       8 |     Name        = "Sensitive Storage Bucket"

  See https://github.com/tfsec/tfsec/wiki/AWS001 for more information.

```

The default value as been evaluated from the `variables.tf` file and seen that without explicitly overriding the value would have the same net effect as hard coding it to `public-read`

### False Positive

Assuming that you did intend to ignore this error for this resource, that is fine, it can be done by adding an ignore declaration to the resource;

```terraform
resource "aws_s3_bucket" "my-bucket-for-secret-things" {
  bucket = "my-bucket-for-secret-things"
  #tfsec:ignore:AWS001
  acl    = var.bucket-acl

  tags = {
    Name        = "Sensitive Storage Bucket"
    Environment = "Production"
  }
}

```

### More information

Check out the [github project](https://www.github.com/tfsec/tfsec) for more information


### A note on Terraform

If it sounds like something you want to learn more about then check out [`Terraform: From Beginner to Master` by Kevin Holditch](https://leanpub.com/terraform-from-beginner-to-master)
