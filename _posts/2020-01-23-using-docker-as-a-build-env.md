---
layout: post
title: "Using Docker Multi stage build"
date: 2020-01-25 12:10:59
image: '/assets/img/blog-author.png'
description: A walkthrough of using Docker multi stage build Docker files to build an image containing an example Go application
tags: [go, docker]
categories: [Programming, SysAdmin]
twitter_text: Using Docker multi stage builds
---

I have been using using Docker and Kubernetes off and on for work and personal for a few years now, but I was recently shown a feature in the Docker file that I wasn't aware of.

A bit of background - I was building a Go application that would sit alongside Squid to perform some updates. Although I was building the appliction with `GOOS` configured, the created Docker image would only work on my Macbook. Setting `GOARCH` also fixed it, but this is more interesting and certainly more portable solution.

## Multi Stage 

Since version [17.06.1-ee-1](https://docs.docker.com/engine/#17061-ee-1), Docker has added support for multi stage build in the Docker file. This means you can build your code in on container and make it available to other image builds. The obvious benefit of this for my case is that the target base image can be used as the build env too.

## An Example

I wanted to provide a very basic example, so I thought I would create a dummy application that I could build the Dockerfile for.

### The Application

The application is going to provide a simple web server that when passed a status code in the path with return a response with that code. This could be potentially useful if you want to test getting various status codes in the wild.

I am writing the application in Go because that is the language I have started using at work - so its all good practice.

#### HTTP Server

The application creates an HTTP server to listen on port 8080 and return the response with an appropriate status code.

```go
package example

import (
	"fmt"
	"net/http"
	"os"
	"strconv"
)

func StartServer(stop chan bool) {
	start := make(chan bool, 1)

	http.HandleFunc("/", HttpCodeServer)3

	go func() {
		for {
			select {
			case <-start:
				println(fmt.Sprintf("Starting the service on %s", port))
				err := http.ListenAndServe("0.0.0.0:8080", nil)
				if err != nil {
					println("Restarting the server...")
					start <- true
				}
			case <-stop:
				break
			}

		}
	}()
	println("Starting the server...")
	start <- true
}


func HttpCodeServer(w http.ResponseWriter, r *http.Request) {
	statusCode, err := strconv.Atoi(r.URL.Path[1:])
	if err != nil {
		fmt.Fprintf(w, "Couldn't handle status code %s!", r.URL.Path[1:])
	}
	w.WriteHeader(statusCode)
}

```

#### Main command

The application needs an entry point, this is found in `main.go` under `cmd/httpcodes` path.

```go
package main

import (
	"httpcodes/internal/app/example"
	"os"
	"os/signal"

)

func main() {
	stopServer := make(chan bool, 1)
	stop := make(chan os.Signal, 1)
	signal.Notify(stop, os.Interrupt)

	go func() {
		stopServer <- <-stop == os.Interrupt
	}()
	httpcodes.StartServer(stopServer)
	<-stop
}
```
This code starts the httpcodes server which will do the listening. A channel is used to stop the server when the application recieves a `SIGINT`.

### Folder Structure

I have followed the folder structure laid down in the [Go project layout guide](https://github.com/golang-standards/project-layout).

This puts the `Dockerfile` into the `build/packages` structure.

```
.
├── build
│   └── package
│       └── httpcodes
│           └── Dockerfile
├── cmd
│   └── httpcodes
│       └── main.go
└── internal
    └── app
        └── httpcodes
            └── server.go
```

### Dockerfile

This was the original point of the post, the `Dockerfile`. 

```docker
FROM golang:alpine AS builder

ENV SRCPATH $GOPATH/src/httpcodes
COPY ./ $SRCPATH
RUN go install httpcodes/cmd/httpcodes

FROM alpine:3.11.3

EXPOSE 8080

RUN mkdir -p /app
COPY --from=builder /go/bin/httpcodes /app/
RUN chmod +x /app/httpcodes

CMD ["./app/httpcodes"]
```

I have kept it deliberately straight forward to highlight the main point.

At the top I am using `golang:alpine` which has all the required packages already installed to build my application. Notice that I mark this `AS builder`. 

Now, when I create the actually build of the main image, in the `COPY` command you can see that the `--from=builder` attribute is used. This attribute is telling the second image to grab the `/go/bin/httpcodes` binary from the output of the first stage and copy them to the `/app` folder.

### Building and Running

All that is left now is to build and run. From the root of the project run;

```
docker build -t httpcodes -f build/package/httpcodes/Dockerfile .
```

This will build the project and you can now run it with;
```
docker run -d -p 8080:8080 httpcodes
```

This command will start the image with port `8080` mapped to the host machine so we can access it. The `-d` just runs it in detached mode.

### Testing

To test, execute a curl command against `localhost:8080/` passing a status code.

for example;
```
curl -v http://localhost:8080/502
```

This should return a verbose message saying we got a `502`

```shell
*   Trying 127.0.0.1...
* TCP_NODELAY set
* Connected to localhost (127.0.0.1) port 8080 (#0)
> GET /502 HTTP/1.1
> Host: localhost:8080
> User-Agent: curl/7.64.1
> Accept: */*
>
< HTTP/1.1 502 Bad Gateway
< Date: Sat, 25 Jan 2020 13:02:31 GMT
< Content-Length: 0
<
* Connection #0 to host localhost left intact
* Closing connection 0
```