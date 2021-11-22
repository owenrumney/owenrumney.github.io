---
layout: post
author: Owen Rumney
title: Quick introduction to pyspark
tags: [pyspark, python, spark]
categories: [Programming, Spark]
---

All the work I have been doing with AWS has been using Python, specifically [boto3](http://boto3.readthedocs.org/en/latest/) the rework of boto.

One of the intentions is to limit bandwidth when transferring data to S3 the idea is to send periodic snapshots then daily deltas to merge and form a **_latest_** folder so a diff mechanism is needed - I originally implemented this in Scala as a Spark process but in an effort to settle on one language I'm looking to redo in Python using [pyspark](https://spark.apache.org/docs/0.9.0/python-programming-guide.html)

I'm using my Macbook and to keep things quick and easy I'm going to download a package with Hadoop and Spark then dump it in `/usr/share`

```text
wget http://archive.apache.org/dist/spark/spark-1.0.2/spark-1.0.2-bin-hadoop2.tgz
tar -xvf spark-1.0.2-bin-hadoop2.tgz
mv spark-1.0.2-bin-hadoop2 /usr/share/spark-hadoop

```

I'm going to create a folder to do my dev in under my home folder, to keep things clean I like to use [virtualenv](https://pypi.python.org/pypi/virtualenv)

```text
cd ~/dev
virtualenv pyspark
cd pyspark
```

To start pyspark with IPYTHON we need to start it with some IPYTHON_OPTS

```text
IPYTHON_OPTS="notebook" /usr/share/spark-hadoop/bin/pyspark
```

This opens IPython notebook in the default browser.

Finally, a quick and dirty demo with word count

```python
file = sc.textFile("/data/bigtextfile.txt")
counts = file.flatMap(lambda line: line.split(" ")) \
             .map(lambda word: (word, 1)) \
             .reduceByKey(lambda a, b: a + b)
counts.saveAsTextFile("/data/bigtextfile.txt")
```
