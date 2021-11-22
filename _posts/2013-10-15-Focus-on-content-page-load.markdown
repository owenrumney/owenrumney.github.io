---
layout: post
author: Owen Rumney
tags: [sharepoint, office 365, javascript, sharepoint]
title: Focus on content on page load
---

One of the requirements for a piece of SharePoint/Office 365 work I'm working on at the moment is for easy finger usage when accessing with an iPad. The user base coming in on iPad are performing a specific task so a lot of the navigation and quick launch is not really applicable to them.

I have been looking at the best way to achieve this and found that calling the existing Javascript function is going to do fine for this need.
{% highlight javascript %}
\$(document).ready(function () {
SetFullScreenMode(true); // or false to close full-screen
});
{% endhighlight %}

There was another option to set the css when the page loaded but this approach is cleaner
