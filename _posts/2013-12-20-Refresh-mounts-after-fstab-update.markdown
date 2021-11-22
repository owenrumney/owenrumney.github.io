---
title: Refresh Linux mounts after changes made to /etc/fstab
tags: [linux, fstab, hardware]
layout: post
author: Owen Rumney
categories: [SysAdmin]
---

When an update has been made to /etc/fstab the changes won't immediately and automatically take effect so there is a need to refresh them manually.

This can be done either by rebooting, which is a pain or just use the mount command

{% highlight sh %}
mount -a
{% endhighlight %}
