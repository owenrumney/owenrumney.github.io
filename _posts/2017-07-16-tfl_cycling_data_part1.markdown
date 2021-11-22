---
layout: post
author: Owen Rumney
title: TFL Cycling DataSet - Part 1
tags: [python, programming, spark, learning, datasets]
categories: [Spark, Programming]
---

I'm hoping this will be a reasonably accurate account of my play with the [TfL Cycling DataSets](http://cycling.data.tfl.gov.uk).

I'm still forming my plan, however loosely I think I want to end up with a visualisation where the bike points are highlighted in over a time series as bikes are taken and returned.

Initially, I'm working on my Mac, but I have a [Databricks community](https://community.cloud.databricks.com/) cluster that I've migrated some of the parts to.

## Preparing my Local Env

As I said, I'm using my MacBook so I'm going to install a couple of things

### Install Spark

To install spark, I use `brew`

```
brew install spark
```

### Install Jupyter

Installing jupyter notebooks is done with `pip`

```
pip install jupyter
```

### Getting some data

I took a single file from the S3 bucket to play with locally, for no particular reason I went with `01aJourneyDataExtract10Jan16-23Jan16.csv`

```
aws s3 cp s3://cycling.data.tfl.gov.uk/usage-stats/01aJourneyDataExtract10Jan16-23Jan16.csv ~/datasets/cycling/.
```

### Starting Up

Run the following commands to get your Jupyter Notebook up and running

```
export PYSPARK_DRIVER_PYTHON=jupyter
export PYSPARK_DRIVER_PYTHON_OPTS='notebook'
pyspark
```

## Quick Test

Finally a quick test to see how it looks. In the `Jupyter notebook` I can do

```python
data = spark.read.csv('~/datasets/cycling/01aJourneyDataExtract10Jan16-23Jan16.csv', header=True, inferSchema=True)
data.show()
```

This should show you 20 rows from the data set and we're off.
