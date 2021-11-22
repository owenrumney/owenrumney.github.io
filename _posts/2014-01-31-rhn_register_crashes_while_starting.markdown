---
layout: post
author: Owen Rumney
title: rhn_register crashes while starting
tags: [red hat, linux, work stuff]
categories: [SysAdmin]
---

I'm setting up a tactical farm of Linux servers on some desktops till we can get the permanent kit installed in the data center.

The new servers are running on trader desktops so they're reasonably good kit. Too satisfy security requirements we need to use a customised build of Red Hat 5 and I'm on the last of the 6 machines.

While trying to run rhn_register on this last machine, it kept starting then crashing straight away with no really error. I dug into the log file and found the following error.

{% highlight sh %}
FatalErrorWindow(screen, e.errmsg)
exceptions.AttributeError: SSLCertificateVerifyFailedError instance has not attribute 'errmsg'
{% endhighlight %}

I'm sure you'll agree that from this exception it's obvious what the problem is? No? Well chances are, its the datetime of the machine. In my case it thought it was 24th October 2010.

A quick `date -s` and all was sorted.
