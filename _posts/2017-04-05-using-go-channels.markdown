---
layout: post
author: Owen Rumney
title: Go routines and channels
tags: [go, golang, coding]
---

I'm having a bit of a dabble with Go, as a by product of working with Elastic Search beats.

One thing I've been looking at today is the channels to allow two `go` routines to communicate with each other and I came up with a fairly cheesy way to play with implementing them.

```go
package main

import "fmt"

func ping(c chan string) {
	for {
		msg := <-c
		if msg == "pong" {
			println(" .... " + msg)
			c <- "ping"
		}
	}
}

func pong(c chan string) {
	for {
		msg := <-c
		if msg == "ping" {
			print(msg)
			c <- "pong"
		}
	}
}

func main() {
	var c chan string = make(chan string)

	go ping(c)
	go pong(c)

	c <- "ping"
	var input string
	fmt.Scanln(&input)
}

```

Using the `go` keyword to essentially start the `ping` and `pong` in the `logical processor` and run concurrently. They both get passed a special `chan` string that acts as a shared channel for them to synchronise against.

The code results in an endless game of ping pong.

```
ping .... pong
ping .... pong
ping .... pong
ping .... pong
ping .... pong
ping .... pong
```

There you go. Almost certainly not the best Go ever written, but a start.
