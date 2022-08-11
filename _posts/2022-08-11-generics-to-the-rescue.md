---
layout: post
title: Generics to the Rescue
date: 2022-08-11 00:00:00
image: '/assets/img/owen.png'
description: A tale of performance improvements using Generics
tags: [performance, generics, golang, programming]
categories: [Programming]
twitter_text: A tale of performance improvements using Generics
---
![Generics To the Rescue](../images/generics-to-the-rescue.png)

### A bit of background

I'm working on a tool that uses the [AWS Go SDK](https://aws.github.io/aws-sdk-go-v2/docs/){:target="_blank"} to pull back a lot of information about an account using the API.

Some services require several secondary API calls - for example to get a full picture about an S3 bucket with details about encryption, policies, ACL, logging, versioning and Public Access Block configuration requires six more calls.

When dealing with a medium to large number of buckets, making these calls sequentially is time consuming; extrapolating that over many services and you have a processing time that is not insignificant.

### A bit more detail

Lets put a little bit more detail around this and take SQS for example.

The first thing that we need to do is get all of the SQS queues. The API returns them in pages, so that needs to be handled too...

```go
client = sqs.NewFromConfig(ctx.SessionConfig()) // import "github.com/aws/aws-sdk-go-v2/service/sqs/types"

var apiQueueURLS []string
var input types.ListQueuesInput // import "github.com/aws/aws-sdk-go-v2/service/sqs/types"
for {
	output, err := a.client.ListQueues(a.Context(), &input)
	if err != nil {
		return nil, err
	}
	apiQueueURLs = append(apiQueueURLs, output.QueueUrls...)
	if output.NextToken == nil {
		break
	}
	input.NextToken = output.NextToken
}

```

We now have a list of all the `QueueURLs` for a given region, but we likely need more information than that so we're going to have to make some more calls.

We want to populate the data in a our `Queue` object
```go
type Queue struct {
	QueueURL   string
	Encryption Encryption
	Policies   []iam.Policy
}

type Encryption struct {
	KMSKeyID          string
	ManagedEncryption bool
}
```

If we create a function to get the details - with some of the logic removed for brevity

```go
func adaptQueue(queueUrl string) (*Queue, error) {

	// make another call to get the attributes for the Queue
	queueAttributes, err := a.client.GetQueueAttributes(a.Context(), &sqs.GetQueueAttributesInput{
		QueueUrl: aws.String(queueUrl),
		AttributeNames: []types.QueueAttributeName{
			types.QueueAttributeNameSqsManagedSseEnabled,
			types.QueueAttributeNameKmsMasterKeyId,
			types.QueueAttributeNamePolicy,
			types.QueueAttributeNameQueueArn,
		},
	})
	if err != nil {
		return nil, err
	}

	queueARN := queueAttributes.Attributes[string(types.QueueAttributeNameQueueArn)]
	queue := &sqs.Queue{
		QueueURL: queueUrl,
		Policies: []iam.Policy{},
		Encryption: sqs.Encryption{
			KMSKeyID:          "",
			ManagedEncryption: false,
		},
	}

	sseEncrypted := queueAttributes.Attributes[string(types.QueueAttributeNameSqsManagedSseEnabled)]
	kmsEncryption := queueAttributes.Attributes[string(types.QueueAttributeNameKmsMasterKeyId)]
	queuePolicy := queueAttributes.Attributes[string(types.QueueAttributeNamePolicy)]

	if sseEncrypted == "SSE-SQS" || sseEncrypted == "SSE-KMS" {
		queue.Encryption.ManagedEncryption = true
	}

	if kmsEncryption != "" {
		queue.Encryption.KMSKeyID = kmsEncryption
	}

	if queuePolicy != "" {
		policy, err := iamgo.ParseString(queuePolicy) // import "github.com/liamg/iamgo"
		if err == nil {
			queue.Policies = append(queue.Policies, iam.Policy{
				Document: iam.Document{
					Parsed:   *policy,
				},
				Builtin: false,
			})
		}

	}
	return queue, nil
}
```

In this case, we only had to make a single additional request to the API, but the argument is clear for trying to parallelise this process a little.

### What do we want to do?

Ideally, we would get the list of queues so we know how many we're talking about and this can drive our progress mechanism we might have in out UX. 

Once we have the list of URLs, we want to parallelise the adaption process. But wait!! the `adaptQueue` function in this case takes a `[]string`, but for buckets it might be an `[]s3.Bucket` object or with IAM an `[]iam.Role`.

We need a generic function that will take the slice of inputs and a function to call for each item.

# Generics to the rescue

Lets say out input (in this case a `[]string`) is type `T` and the output we want (in this case a `[]Queue`) is type `S`, we can create a generic function to handle this

```go
func ParallelAdapt[T any, S any](items []T adapt func(T) (*S, error)) []S {
	processes := getProcessCount(DefaultStrategy)

    mu := sync.Mutex{}
    var results []S

    var ch = make(chan T, 50)
	wg := sync.WaitGroup{}
	wg.Add(processes)

	for i := 0; i < processes; i++ {
		go func() {
			for {
				in, ok := <-ch
				if !ok {
					wg.Done()
					return
				}
				out, err := adapt(in)
				if err != nil {
					log.Debug("Error while adapting resource %v: %w", in, err)
					continue
				}

				if out != nil {
					mu.Lock()
					results = append(results, *out)
					mu.Unlock()
				}
			}
		}()
	}

	for _, item := range items {
		ch <- item
	}

	close(ch)
	wg.Wait()

	return results
}
```

Let's break down this function - first, we use a strategy that we've used to get the number of processes to run.

We need to keep in mind the rate limiting of AWS API so there is no point using unbounded number of go routines.

```go
type Strategy int

const (
	DefaultStrategy Strategy = iota
	CPUCountStrategy
	OneAtATimeStrategy
)

func getProcessCount(strategy Strategy) int {
	switch strategy {
	case OneAtATimeStrategy:
		return 1
	case CPUCountStrategy, DefaultStrategy:
		return runtime.NumCPU()
	default:
		// this shouldn't be reached but at least we don't crash
		return 1
	}
}
```

In this example, we're running as many Go routines as we have CPUs. 

The next thing to create a slice of results of type `S` (in this case `[]Queue`) where our results are going to go. We need a `sync.Mutex` here to safely add items to the slice.

Now for the concurrency bit...

We create a `sync.WaitGroup` that has space for the number of process we're going to use. 

We also create a channel with an arbitrary number of slots where we're going to push the inputs of type `T` for processing.

Next, we create as many Go routines as we have processes that takes a value off the channel `ch` and if its ok, it will run the `adapt` function provided against the value of type `T`. We get an error and an output result of type `S` from the function which we can safely add to the `results` then the go routine can go back to the channel for another item of work.

The last step is to add everything to the channel - we loop over the items (in this case `strings`) sending them to the channel. When this is done, we `close` the channel to tell it nothing else is coming then `Wait` for the `WaitGroup` to be done (this is done when the channel has nothing else on it, and each process will complete).

Finally, we return the results back to the caller.

### Using the function

We can easily use this function, sticking with the same example we would call

```go
results := ParallelAdapt(apiQueueURLS, adaptQueue) // we have a slice of *Queue
```

The number of concurrent calls is always something that needs to be analysed and a suitable trade off come to. You don't want to create IO issues in the name of concurrency.

