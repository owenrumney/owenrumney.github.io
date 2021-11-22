---
layout: post
author: Owen Rumney
title: Creating a simple Dockerised Flask App
description: Walkthrough on the steps required to create a flask app that can run within a docker container
tags: [docker, flask, python, tutorial]
---

This post covers the steps to create a simple dockerised flask app to cover some of the basic steps required when creating a REST(ish) service that can be run as a Docker container.

## The App
Rather than go with the obvious "Hello, World!" type example, I decided I'd try and do something just a touch more interesting and create a REST(ish) resource that will return a response with the status code that was passed in the path of the request. This might be useful for test frameworks where you want to validate some codes reaction to a given response status code or similar.

I'm using Flask to create a quick an dirty solution, mostly to keep it simple. Firstly, the `requirements.txt` file is simple, just one requirement;

```
flask
```
*requirements.txt*

This will get us the Flask package to use in our simple REST(ish) service, which is essentially this; (forgive the inline `status_codes` dict)

```python
import json
from flask import Flask, Response 

status_codes = {
        "100": "Continue",
        "101": "Switching Protocols",
        "102": "Processing",
        "103": "Early Hints",
        "200": "OK",
        "201": "Created",
        "202": "Accepted",
        "203": "Non-Authoritative Information",
        "204": "No Content",
        "205": "Reset Content",
        "206": "Partial Content",
        "207": "Multi-Status",
        "208": "Already Reported",
        "226": "IM Used",
        "300": "Multiple Choices",
        "301": "Moved Permanently",
        "302": "Found",
        "303": "See Other",
        "304": "Not Modified",
        "305": "Use Proxy",
        "307": "Temporary Redirect",
        "308": "Permanent Redirect",
        "400": "Bad Request",
        "401": "Unauthorized",
        "402": "Payment Required",
        "403": "Forbidden",
        "404": "Not Found",
        "405": "Method Not Allowed",
        "406": "Not Acceptable",
        "407": "Proxy Authentication Required",
        "408": "Request Timeout",
        "409": "Conflict",
        "410": "Gone",
        "411": "Length Required",
        "412": "Precondition Failed",
        "413": "Payload Too Large",
        "414": "URI Too Long",
        "415": "Unsupported Media Type",
        "416": "Range Not Satisfiable",
        "417": "Expectation Failed",
        "421": "Misdirected Request",
        "422": "Unprocessable Entity",
        "423": "Locked",
        "424": "Failed Dependency",
        "425": "Too Early",
        "426": "Upgrade Required",
        "428": "Precondition Required",
        "429": "Too Many Requests",
        "431": "Request Header Fields Too Large",
        "451": "Unavailable For Legal Reasons",
        "500": "Internal Server Error",
        "501": "Not Implemented",
        "502": "Bad Gateway",
        "503": "Service Unavailable",
        "504": "Gateway Timeout",
        "505": "HTTP Version Not Supported",
        "506": "Variant Also Negotiates",
        "507": "Insufficient Storage",
        "508": "Loop Detected",
        "510": "Not Extended",
        "511": "Network Authentication Required"
}

app = Flask(__name__)

@app.route('/<code>', methods=['GET', 'POST', 'HEAD', 'PUT'])
def status_code(code):
    message = status_codes.get(code, "Unknown Status Code")
    return Response(status=int(code), response=message)


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')

```
*app.py*

You can test the code by running `python app.py` which will launch the app on port 5000. Quick test might be;

```
curl -v http://localhost:5000/405
```

All being well, this will give you a response of

```
*   Trying ::1...
* TCP_NODELAY set
* Connection failed
* connect to ::1 port 80 failed: Connection refused
*   Trying 127.0.0.1...
* TCP_NODELAY set
* Connected to localhost (127.0.0.1) port 5000 (#0)
> GET /405 HTTP/1.1
> Host: localhost
> User-Agent: curl/7.54.0
> Accept: */*
>
* HTTP 1.0, assume close after body
< HTTP/1.0 405 METHOD NOT ALLOWED
< Content-Type: text/html; charset=utf-8
< Content-Length: 18
< Server: Werkzeug/0.14.1 Python/3.7.2
< Date: Sat, 19 Jan 2019 16:26:34 GMT
<
* Closing connection 0
Method Not Allowed%
```

NOTE, the response status is the code that we've passed `HTTP/1.0 405 METHOD NOT ALLOWED`

## Running it as a Docker container

### Installing Docker

First, you're going to need to have Docker on your machine. Best approach is going to be downloading the [Docker Desktop](https://www.docker.com/products/docker-desktop) for your particular machine.

### Creating the DockerFile

Dockerfiles require a base image to start from, for a lightweight Python container we can just use the Alpine image to derive our container. This image is a minimal Docker image which is only 5mb in size. You can [learn more about Alpine here](https://hub.docker.com/_/alpine)

The Dockerfile below is all that we're going to need. It assumes the basic file structure of the project is similar to the tree below;

```
.
├── Dockerfile
├── app
│   ├── __init__.py
│   └── app.py
└── requirements.txt
```

We've covered `app.py`, `requirements.txt` and `__init__.py` is an empty file. All thats left is the Dockerfile

```
FROM python:alpine

EXPOSE 5000

# Copy over the application
WORKDIR /app
COPY . /app

RUN python3 -m pip install -r requirements.txt

# Start the application
CMD ["python3", "app/app.py"]
```
*Dockerfile*

Breaking this down we're saying that our image is 
* going to be based on the `python:alpine` image. 
* going to expose something on port 5000 (in this case the app)
* going to use /app as its working directory
* going to copy the contents of `app` to the `/app` folder on the image
* going to install the requirements as specified in `requirements.txt`
  
Finally, we end with the `CMD` which specifies what will happen when the container starts. In this case, we're going to be starting the Flask app.

### Building the docker file

We need to build the image to be able to use it. This is assuming you've installed and started Docker on your machine. 

To build the image we used the `docker build` command.

```
docker build . -t httpcodes:latest
```

This will give an output with the steps that are performed while building the image

```
Sending build context to Docker daemon  11.78kB
Step 1/7 : FROM python:alpine
 ---> 1a8edcb29ce4
Step 2/7 : LABEL Name=docker Version=0.0.1
 ---> Using cache
 ---> 2076201409c8
Step 3/7 : EXPOSE 3000
 ---> Using cache
 ---> 63588eaed844
Step 4/7 : WORKDIR /app
 ---> Using cache
 ---> feb03f342d39
Step 5/7 : ADD . /app
 ---> Using cache
 ---> fe2d365303a5
Step 6/7 : RUN python3 -m pip install -r requirements.txt
 ---> Using cache
 ---> b3ecdb9890ad
Step 7/7 : CMD ["python3", "app/app.py"]
 ---> Using cache
 ---> 1616f252e49d
Successfully built 1616f252e49d
Successfully tagged httpcodes:latest
```

We can now run the image

```
docker run -d -p 80:5000 httpcodes
```

This command is telling Docker to start a container based on the httpcodes (infering latest because no version was specified) and to do a port forward from the host (your machine) to port 5000 on the container. In this case, we're saying route all traffic that comes to http://localhost:80 to 5000 on the container.

### Testing the endpoint

As before, we can test the endpoint to make sure it does as we expected.

```
curl -v http://localhost/405
```

All being well, this will give you a response of

```
*   Trying ::1...
* TCP_NODELAY set
* Connection failed
* connect to ::1 port 80 failed: Connection refused
*   Trying 127.0.0.1...
* TCP_NODELAY set
* Connected to localhost (127.0.0.1) port 80 (#0)
> GET /405 HTTP/1.1
> Host: localhost
> User-Agent: curl/7.54.0
> Accept: */*
>
* HTTP 1.0, assume close after body
< HTTP/1.0 405 METHOD NOT ALLOWED
< Content-Type: text/html; charset=utf-8
< Content-Length: 18
< Server: Werkzeug/0.14.1 Python/3.7.2
< Date: Sat, 19 Jan 2019 16:26:34 GMT
<
* Closing connection 0
Method Not Allowed%
```
