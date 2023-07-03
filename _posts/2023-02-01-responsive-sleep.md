---
layout: post
title: Sleeping responsively
date: 2023-02-01 00:00:00
image: "/assets/img/owen.png"
description: Handle context cancellation during a sleep
tags: [go, learning]
categories: [programming]
twitter_text: Handle context cancellation during a sleep
---

How do you have a long polling mechanism that can be cancelled even during it's sleep? THis is a question I found myself facing recently with a CLI app that is polling AWS Cloud Watch

Let's say you have a function that looks like this:

```go
func Start () {
    ctx, cancel := context.WithCancel(context.Background())
    defer cancel()

    // create a channel for signals and listen for SIGINT and SIGTERM
    c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt, syscall.SIGTERM)
    // cancel the context when we receive a signal
	go func() {
			<-c
			cancel()
	}()

    poll(ctx)

}

func poll(ctx context.Context) {
    for {
        select {
        case <-ctx.Done():
            return
        default:
            // do some work

            // sleep for 1 minute
            time.Sleep(1 * time.Minute)
        }
    }
}
```

The problem we have here is that when we cancel the context while it's in the sleep phase it will not be cancelled until the sleep is over. This is because the `time.Sleep` function is not a cancellable function.

The way I solved it, and it's certainly not going to be the only way, was to create a simple sleep function that made use of the `time.After` function.

```go
func sleep(ctx context.Context, delay time.Duration) {
	select {
	case <-ctx.Done():
	case <-time.After(delay):
	}
}
```

So now my code looks like this:

```go
func Start () {
    ctx, cancel := context.WithCancel(context.Background())
    defer cancel()

    // create a channel for signals and listen for SIGINT and SIGTERM
    c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt, syscall.SIGTERM)
    // cancel the context when we receive a signal
	go func() {
			<-c
			cancel()
	}()

    poll(ctx)

}

func poll(ctx context.Context) {
    for {
        select {
        case <-ctx.Done():
            return
        default:
            // do some work

            // sleep for 1 minute
            sleep(ctx, 1 * time.Minute)
        }
    }
}

func sleep(ctx context.Context, delay time.Duration) {
	select {
	case <-ctx.Done():
	case <-time.After(delay):
	}
}
```

Now if the context is cancelled while the sleep is in progress it will be cancelled immediately.
