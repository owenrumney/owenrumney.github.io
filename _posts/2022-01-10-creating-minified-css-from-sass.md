---
layout: post
title: "Creating minified CSS from SASS"
date: 2022-01-10 00:00:00
image: '/assets/img/blog-author.png'
description: Reminder for creating minified css from sass file
tags: [css, sass, minification]
categories:
twitter_text: Creating minified css from sass
---

I am having a baptism of fire with UI development updating a stalled knowledge base at work.  

One of the entirely new technologies I'm picking up is sass for style sheets; the workflow of `compile` -> `minify` seemed clunky and it turns out they can be combined into a single command

```bash
sass combined.sass:../css/combined.min.css --style compressed
```