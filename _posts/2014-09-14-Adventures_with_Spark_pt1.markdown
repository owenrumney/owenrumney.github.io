---
layout: post
author: Owen Rumney
title: Adventures with Spark, part one
tags: [spark, scala]
categories: [Programming, Spark]
---

For 18 months I've been working with Hadoop. Initially it was Hortonworks HDP on Windows then Hortonworks HDP on CentOS and for production we settled on Cloudera CDH5 on Red Hat. Recently we've been introduced to Spark and subsequently Scala which I am now in the process of skilling up on, the plan is to blog as I learn.

For the first entries I imagine it won't be much more than the basic tutorial you could read elsewhere, however the plan is to get more detailed as I learn more.

I can't introduce Scala better than [Scala School](https://twitter.github.io/scala_school/) so its worth taking a look at that.

I am going to use JetBrains IntelliJ IDEA for developing fuller applications, however for playing and learning you can download Spark for Hadoop in TAR format from the [Spark Download Page](http://spark.apache.org/downloads.html) and use the Spark shell.

For now I just extracted it to a folder in Downloads;

To start the Spark shell

{% highlight sh %}
\$ cd ~/Downloads/spark-1.0.2-bin-hadoop2/bin
./spark-shell
{% endhighlight %}

One of the key parts to Spark is the `SparkContext` which if you've done mapreduce seems to be similar to the `JobConf`. The SparkContext has all the required information about where to run the work and application details for view in the Spark UI web page.

In the spark shell you can use the SparkContext `sc`

{% highlight scala %}

scala> val sentence = "The quick brown fox jumps over the lazy dog"
scala> val words = sc.parallelize(sentence)
scala> words.count() // should return 9  
scala> words.filter(\_.toLowerCase() == "the").count() // should return 2

{% endhighlight %}

All this is doing is creating a string, splitting it into words and creating a Spark RDD with it. We can use the `Action` count() to find out how many words there are and we can use the filter() to create a new RDD with filtered results (in this case, filter to the word 'the')
