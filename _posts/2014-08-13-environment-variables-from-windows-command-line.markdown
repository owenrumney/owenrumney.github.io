---
layout: post
author: Owen Rumney
title: Creating environment variables from the command line (Windows)
tags: [windows, system, configuration]
categories: [SysAdmin]
---

I know that it is incredibly lazy and a non problem but I find it quite tedious in Windows 8 to go digging for the system environment variable GUI whenever I need to add or update something.

Generally I'm already in the command prompt so I was keen to find a way to create them from there without having to go into search for it each time.

Since Windows XP, setx has been available as an extra download, and more recently it's included in Windows out of the box - this is the command that I wanted.

To create a persistent STORM_HOME environment variable, use the following command. The /M sets it as a system variable rather than the default user variable.

{% highlight sh %}
setx /M STORM_HOME d:\storm-latest
{% endhighlight %}

There are a number of other options, do `setx /?` to see them.
