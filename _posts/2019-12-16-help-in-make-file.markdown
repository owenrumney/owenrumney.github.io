---
layout: post
title: Adding Help to a Makefile
description: Add a quick help section to a Makefile
tags: [make,documentation]
categories: [SysAdmin]
---

Sometimes you inherit or even create a huge `Makefile` which is unwieldly and difficult to understand. The longer it is, the more complicated it can be to find out which targets are available and what they do.

This post covers an effective way to add a help target to a `Makefile` which will give an overview of what targets are available.

## Basic Makefile

I'm going to use a really basic but real `Makefile` as a starting example. It runs a suite of tests, creates a dockerised environment for testing against or can stop the env.

```make
 test:
 ## test: Run the test suite then shut down
   docker-compose up --abort-on-container-exit --exit-code-from tests

 dev:
 ## dev: Create an environment in docker to develop against
   docker-compose -f docker-compose-local.yml up -d

 stop:
 ## stop: Stop the docker instances for dev
   docker-compose down
```

Lets imagine that there are another 20 targets available including dependency management, build, build with unit tests, package, publish etc. Getting this as a new joiner, I'd have to open the file and read it through to get an idea of what options were available and what each one did.

## Adding Help

To add a `help` section, we can put a comment under each of the targets with details of the action, then use a simple hand full of commands including `sed` and `column` in the `help` target.


```make
 test:
 ## test: Run the test suite then shut down
   docker-compose up --abort-on-container-exit --exit-code-from tests

 dev:
 ## dev: Create an environment in docker to develop against
   docker-compose -f docker-compose-local.yml up -d

 stop:
 ## stop: Stop the docker instances for dev
   docker-compose down

 help:
 ## help: This helpful list of commands
   @echo "Usage: \n"
   @sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' | sed -e 's/^/-/'
```

What this target does is find all of the entries starting `##` in all of the Makefiles that have been loaded (this is stored in the `MAKEFILE_LIST` env var). 
Once the comment lines have been gathered, they are piped to column to format into a table, splitting on the colon `:`.
Finally, the front of the line is replaces with a dash, to get the breakdown of comments. 

## Running Make with help   

Now we can run `make help` to get more information about the available targets.

This will give us the result;

```shell
$ make help
Usage:

- test   Run the test suite then shut down
- dev    Create an environment in docker to develop against
- stop   Stop the docker instances for dev
- help   this helpful list of command
```

That's it, the more tasks there are, the more that this can be useful. Ultimately, it is only as useful as the quality and accuracy of the comments.
