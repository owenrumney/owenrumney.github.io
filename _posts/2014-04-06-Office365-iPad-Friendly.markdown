---
title: Office365 and SharePoint iPad Friendly
layout: post
author: Owen Rumney
tags: [office 365, sharepoint, ipad, css]
---

I have been doing some work for a company who have a user base who primarily use iPads to access the SharePoint site. There was a requirement to allow those users to easily access the team site without getting their screens filled with the quick launch and the bloated title.

Initially, I solved this using by using JavaScript to set the page to full screen;

{% highlight javascript %}

window.onload = function () {

    //alert('has loaded');
    SP.SOD.executeOrDelayUntilScriptLoaded(goToFullScreen, 'sp.js');
    // For use within normal web clients
    function goToFullScreen() {
    	//alert('goToFullScreen');
    	var isiPad = navigator.userAgent.indexOf('iPad') != -1;
    	if(isiPad) {
    		setTimeout(goFullScreen, 500);
    	}
    }

    function goFullScreen() {
    	SetFullScreenMode(true);
    }

    SP.SOD.notifyScriptLoadedAndExecuteWaitingJobs("sp.js");

};

{% endhighlight %}

The problem with this approach was the short delay from the page loading to the screen resizing to remove the side bar etc which was undesirable.

I was asked to find a better way to remove the menus that was more instantaneous so I turned to css media queries.

To achieve this, I looked at what the SharePoint `SetFullScreenMode` function actually did. I found that in addition to setting the cookie, it also applies the `ms-fullscreenmode` css class to the body element, which led me to the following CSS in the master page;

{% highlight css %}

<style>

	@media only screen and (min-device-width: 768px) and (max-device-width: 1024px){

		#navresizerVerticalBar{
			display:none;
		}
		#navresizerHorizontalBar{
			display:none;
		}
		#s4-titlerow {
			display:none !important;
		}
		#sideNavBox {
			display:none;
		}
		#contentBox {
			margin-left:40px;
		}
		#contentBox {
			margin-left:0px;
		}
	}
</style>

{% endhighlight %}
