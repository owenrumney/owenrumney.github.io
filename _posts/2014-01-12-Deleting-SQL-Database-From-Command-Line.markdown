---
layout: post
author: Owen Rumney
title: Deleting SQL database from the command line
tags: [sql, sqlcmd, sharepoint]
---

For one reason or another, my SharePoint 2013 development environment became corrupt and the quickest way to get it up and running again was to start a fresh with SharePoint.

The problem I faced was when running the Products and Technologies tool to configure the instance with the existing sites still there, I compounded these problems by being a little brutal in clearing up the previous virtual directories.

The upshot of all this is that I was left with SQL databases that needed clearing up and no desire to sit and wait for Management Studio Express to download and install just to deal with it.
{% highlight sh %}
sqlcmd -S .\SharePoint
1> EXEC sp_databases
2> GO
1> DROP DATABASE [WSS_content_guid]
2> GO
{% endhighlight %}
