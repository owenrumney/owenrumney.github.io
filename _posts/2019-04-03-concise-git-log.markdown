---
layout: post
title: git alias for concise history
description: Getting more concise git log
tags: [git, alias, nice]
category: Git
---

This is pretty short post. H/T to [@prokopp](https://twitter.com/prokopp) for telling me know about this.

Git allows you to add aliases in your global config - this is the first one I've actually added and all it does is a concise, clearly formatted git log.

To add it to you git global config, just run the command below in your terminal

```
git config --global alias.hist "log --pretty=format:'%h %ad | %s%d [%an]' --graph --date=short"
```

An example of the output from this site's repository in my github account is below.

```
* 8295bc3 2019-03-13 | update the truncator (HEAD -> master, origin/master, origin/HEAD) [owenrumney]
* a014dcc 2019-03-13 | update the diagram for the aws glossary site [owenrumney]
* 608f994 2019-03-01 | Update the aws-glossary diagram [owenrumney]
* a5c519c 2019-02-27 | update disqus [owenrumney]
* f1cb250 2019-02-27 | update image [owenrumney]
* 3b24958 2019-02-27 | add the new post [owenrumney]
* b98a6c2 2019-02-21 | add the announcement page [owenrumney]
* 50b4613 2019-02-21 | Moving AWS Link [owenrumney]
* 9d3530d 2019-02-21 | update with filtering [owenrumney]
* 13d7220 2019-02-21 | update with filtering [owenrumney]
* 7c75ac4 2019-02-21 | Add the category filtering to the aws services page [owenrumney]
* 8a48b45 2019-02-21 | update the aws services page [owenrumney]
* 4fd4bcb 2019-02-20 | update aws services [owenrumney]
* 2dfa138 2019-02-20 | add the aws service page [owenrumney]
* a479a28 2019-02-20 | add AWS Services [owenrumney]
* a123376 2019-02-16 | Add lightsout post [owenrumney]
* b9f95a2 2019-02-16 | update the CNAME [owenrumney]
* edd7bac 2019-02-16 | update the CNAME [owenrumney]
* bbe3221 2019-02-16 | update the excerpt on the home page [owenrumney]
* 9fc9402 2019-01-28 | Update post name [owenrumney]
* a2e68a2 2019-01-28 | Add the images [owenrumney]
... cntd
```

Now I need to dream up some other aliases.... 