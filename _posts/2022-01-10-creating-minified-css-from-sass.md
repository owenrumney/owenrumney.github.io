---
layout: post
title: "Creating minified CSS from SCSS"
date: 2022-01-10 00:00:00

description: Reminder for creating minified css from scss file
tags: [scss]
categories: [Programming]
twitter_text: Creating minified css from scss
---

I am having a baptism of fire with UI development updating a stalled knowledge base at work.  

One of the entirely new technologies I'm picking up is sass for style sheets; the workflow of `compile` -> `minify` seemed clunky and it turns out they can be combined into a single command

```bash
sass combined.scss:../css/combined.min.css --style compressed
```
