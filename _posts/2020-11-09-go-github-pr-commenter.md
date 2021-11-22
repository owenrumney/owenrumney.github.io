---
layout: post
title: "PR Commit Commenting Library"
date: 2020-11-09 00:00:00
image: '/assets/img/blog-author.png'
description: Go library to facilitate writing comments to Github PR commits. Write single or multiline comments using the output of static analysis
tags: [github, go]
categories:
twitter_text: Using Go Github PR Commenter, automate your Github Comments
---

A few weeks ago I wrote [tfsec-pr-commenter-action](https://github.com/tfsec/tfsec-pr-commenter-action){:target="_blank"} , this is a ready to go Github Action that you can drop into your Terraform code repository and have each PR checked for tfsec security issues. 

If you don't know anything about tfsec, you can learn more at [https://tfsec.dev](https://tfsec.dev){:target="_blank"} 

## The PR Commenter

It occurred to me shortly after adding it to some of our projects that the underlying commenter code could be used to comment using any static analysis tool with output. 

Of course, the wrapping action code will be needed to un-marshall the analysis results but the creation of comments could be deferred to another library.

This is where [go-github-pr-commenter](https://github.com/owenrumney/go-github-pr-commenter){:target="_blank"}  comes in. 

## Usage

First, get the library;

```shell
go get github.com/owenrumney/go-github-pr-commenter/commenter
```

Then you need to import the library into your Github Action, or where ever it is being used.

```golang
import (
  "github.com/owenrumney/go-github-pr-commenter/commenter"
)
```

You will need a `GITHUB_TOKEN` to write the comments - if you're using Github Actions you get one created for you when you activate Actions. If you are passing the `GITHUB_TOKEN` as a parameter to the Action called `GITHUB_TOKEN`, it is going to be available to your code as `INPUT_GITHUB_TOKEN`.

```golang
token := os.Getenv("INPUT_GITHUB_TOKEN")
if len(token) == 0 {
  return errors.New("Couldn't find the token")
}
```

Now that we have a token, we can create the Commenter

```golang
owner := "owenrumney"
repo := "go-github-pr-commenter"
prNo := 1


c, err := commenter.NewCommenter(token, owner, repo, prNo)
if err != nil {
    fmt.Println(err.Error())
}
```

We now have a commenter, on creation it checked that it had connectivity and that the PR exists so you would have an error if this wasn't the case.


Let's assume your static analysis results are in a slice call `analysisResults` - you can now iterate over them, and create the comments;

Lets say the `AnalysisResult` looks like this;

```golang
type AnalysisResult struct {
  Filepath  string
  Comment   string
  StartLine int
  EndLine   int
}
```

Now we iterate over the slice

```golang
for _, r := analysisResults {
  err = c.WriteMultiLineComment(r.Filepath, r.Comment, r.StartLine, r.EndLine)
}
```

If `r.StartLine == r.EndLine` the library will detect this and create a single line commit comment.

The error returned can be ignored under certain conditions. For example, if the same comment is being written again, this would return a `commenter.CommentAlreadyWrittenError` which can be dropped on the floor.