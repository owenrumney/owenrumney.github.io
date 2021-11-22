---
layout: post
title: Combining rows into an array in pyspark
description: Yeah, I know how to explode in Spark, but what is the opposite and how do I do it? HINT (collect_list)
tags: [pyspark, python, spark, collect_list, explode]
categories: [Programming]
---

## Overview

I've just spent a bit of time trying to work out how to group a Spark Dataframe by a given column then aggregate up the rows into a single `ArrayType` column.

Given the input;

| transaction_id | item |
| -------------- | ---- |
| 1              | a    |
| 1              | b    |
| 1              | c    |
| 1              | d    |
| 2              | a    |
| 2              | d    |
| 3              | c    |
| 4              | b    |
| 4              | c    |
| 4              | d    |

I want to turn that into the following;

| transaction_id | items        |
| -------------- | ------------ |
| 1              | [a, b, c, d] |
| 2              | [a, d]       |
| 3              | [c]          |
| 4              | [b, c, d]    |

To achieve this, I can use the following query;

```python
from pyspark.sql.functions import collect_list

df = spark.sql('select transaction_id, item from transaction_data')

grouped_transactions = df.groupBy('transaction_id').agg(collect_list('item').alias('items'))
```