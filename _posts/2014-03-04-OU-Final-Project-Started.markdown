---
title: OU Final project finally started
layout: post
author: Owen Rumney
tags: [tma470, open university, final project]
---

At the eleventh hour I finally settled on the project that I am going to be working on for the next 8 months. I had previously intended to work on a project that would allow me to play with some javascript graph layout and visualisation libraries. Unfortunately this intention didn't have enough of a clear direction to make it a solid proposition for a successful project.

So, the project I'm working on is based on my dad's job in modern tram systems. The focus of the project will be to provide a software library that can be used to assist in the validation of chose routes for a tram system. Basically a route is made up of a series of segments that can be straight, curved or a transition from straight to curved. Along the route there may be platforms, crossing, traffic lights etc but essentially these three segment types cover most of it.

When a tram is travelling through a curve there are a number of factors which dictate the speed the tram can travel. Sections of track may have environmental factors which dictate a maximum speed (eg; an area of high pedestrian traffic). The library will seek to provide a journey time for each type of tram through the route by calculating the permissible speed through each segment of the route.

I'll update as I go, you might think its a dry subject, however the calculation logic should make for some interesting challenges.
