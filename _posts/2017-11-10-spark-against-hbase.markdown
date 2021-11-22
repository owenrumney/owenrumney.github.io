---
layout: post
author: Owen Rumney
title: Running Spark against HBase
tags: [programming, spark, hbase, scala]
categories: [Spark, Programming]
---

Its reasonably easy to run a Spark job against HBase using the `newAPIHadoopRDD` available on the `SparkContext`.

The general steps are,

1. create an `HBaseConfiguration`
2. create a `SparkContext`
3. create a `newAPIHadoopRDD`
4. perform job action

To get this working, you're going to need the HBase libraries in your `build.sbt` file. I'm using HBase `1.1.2` at the moment so thats the version I'm pulling in.

```java
"org.apache.hbase" % "hbase-shaded-client" % "1.1.2"
"org.apache.hbase" % "hbase-server" % "1.1.2"
```

### Creating the HBaseConfiguration

This requires, at a minimum, the zookeeper URI. In my environment the test and the production have different `ZOOKEEPER_ZNODE_PARENT` so I'm passing that in to override the default.

```java
def createConfig(zookeeper: String, hbaseParentNode: String, tableName: String): Configuration = {
  val config = HBaseConfiguration.create()
  config.set("zookeeper.znode.parent", hbaseParentNode)
  config.set("hbase.zookeeper.quorum", zookeeper)
  config.set("hbase.mapreduce.inputtable", tableName)
  config
}
```

### Creating the SparkContext

The `SparkContext` is going to be the main engine of the job. At a minimum we just need to have the `SparkConf` with the job name.

```csharp
val conf = new SparkConf().setAppName(jobname)
val spark = new SparkContext(conf)
```

### Creating the newAPIHadoopRDD

We have a `HBaseConfiguration` and a `SparkContext` so now we can create the `newAPIHadoopRDD`. The `newAPIHadoopRDD` needs the config with the table name and namespace and needs to know to use a `TableInputFormat` for the `InputFormat`. We're expecting the class of the keys to be `ImmutableBytesWritable` and for the values a `Result`.

```csharp
val zookeeper = "hbase-box1:2181,hbase-box2:2181"
val hbaseParentNode = "/hbase"
val tableName = "credit_data:accounts"

val config = createConfig(zookeeper, hbaseParentNode, tableName)


val hBaseRDD = spark.newAPIHadoopRDD(config,
                classOf[TableInputFormat],
                classOf[ImmutableBytesWritable],
                classOf[Result])
```

### Performing the Job Action

Thats all we need, we can now run our job. Its contrived, but consider the following table.

| key              | d:cl | d:cb |
| ---------------- | ------------- | ---------------- |
| 1234678838472938 | 1000.00       | 432.00           |
| 9842897418374027 | 100.00        | 95.70            |
| 7880927412346013 | 600.00        | 523.30           |

In our table, we have a key with the credit card number and a `ColumnFamily` of `d:` which holds the `column_qualifiers` `cl (credit limit)` and `cb (current balance)`.

For this job, I want to know all the accounts which are at >90% of their available credit.

```csharp
case class Account(ccNumber: String, limit: Double, balance: Double)

val accountsRDD = hBaseRDD.map(r => {
    val key = Bytes.toStringBinary(t._1.get())
    val result = t._2.getFamilyMap("d")
    val limit = Bytes.toDouble(result.get("cl"))
    val balance = Bytes.toDouble(result.get("cb"))
    Account(key, limit, balance)
})
```

That gives us a nicely typed RDD of Accounts we can use to do our filtering on.

```csharp
val eligibleAccountsRDD = accountRDD.filter(a => {
    (a.balance / a.limit) > 0.9
})
```

That gives the matching accounts which we can now extract the account number for and save to disk.

```csharp
val accountNoRDD = eligibleAccountsRDD.map(a => {
    a.ccNumber
}).saveAsTextFile("/save/location")
```

The save location will now be a folder with the created `part-xxxxx` files containing the results. In our case...

```
9842897418374027
7880927412346013
```
