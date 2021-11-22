---
layout: post
author: Owen Rumney
title: Update Wallpaper from Bing (OSX)
tags: [bing, wallpaper, osx, python]
categories: [Programming]
---

I'm not a huge fan of Bing search engine, I've tried to use it but I don't like the format of the search results and I don't think it's particularly good at finding relevant results either.

I do like Bing wallpapers, and I use Bing Desktop on my Windows laptop to update my desktop to Bings daily wallpaper.

Now that I've moved to a Mac I still want to get the picture, but the application is Windows only - so the script below will do the job for you. I've set it to download to the users picture folder `~/Pictures/bing-wallpapers` just using the current date for the filename.

{% highlight python %}
import urllib2
import json
from os.path import expanduser

response = urllib2.urlopen("http://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=en-US")
obj = json.load(response)

url = (obj['images'][0]['urlbase'])
name = (obj['images'][0]['fullstartdate'])
url = 'http://www.bing.com' + url + '\_1920x1080.jpg'
home = expanduser('~')
path = home +'/Pictures/bing-wallpapers/'+name+'.jpg'
print ("Downloading %s to %s" % (url, path))
f = open(path, 'w')
pic = urllib2.urlopen(url)
f.write(pic.read())
{% endhighlight %}

To run on a schedule, set up a cron job to run the script at 10am using `crontab -e` and add the line

{% highlight sh %}
0 10 \* \* \* python ~/Pictures/wallpaper.py
{% endhighlight %}
