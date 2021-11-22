---
layout: post
author: Owen Rumney
title: Git hangs while unpacking objects (Windows)
tags: [windows, git]
categories: [SysAdmin]
---

I'm not sure if this is because we're behind a proxy, the network has issues or my work laptop isn't great, but for some reason the git clones very often hang during the unpacking of objects.

{% highlight sh %}
remote: Counting objects: 21, done.
remote: Total 21 (delta 0), reused 0 (delta 0)
Unpacking objects: 100% (21/21), done.
{% endhighlight %}

There is a way to recover this, if you `Ctrl+C` to exit the git command then `cd` into the folder cloned into.

{% highlight sh %}
git fsck

notice: HEAD points to the unborn branch (master)
Checking object directories: 100% (256/256), done.
notice: No default references
dangling commit: 0a343894574c872348974a89347c387324324
{% endhighlight %}

The bit we're interested in is the dangling commit, if we merge this commit manually all will be fine

{% highlight sh %}
git merge 0a343894574c872348974a89347c387324324
{% endhighlight %}

Job done, you should now have the completed clone.
