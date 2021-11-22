---
title: Unit testing HDFS code
layout: post
author: Owen Rumney
tags: [hadoop, testing, java]
categories: [Big Data, Programming]
---

I need to write a couple of unit tests for some code to add a log entry into HDFS but I don't want to have to rely on having access to full blown HDFS cluster or a local install to achieve this.

The MiniDFSCluster in `org.apache.hadoop:hadoop-hdfs` can be used to create a quick clustered file system which can be used to testing.

The following dependencies are required for the test to work.

```xml
<dependency>
    <groupId>org.apache.hadoop</groupId>
    <artifactId>hadoop-hdfs</artifactId>
    <version>2.6.0</version>
    <scope>test</scope>
</dependency>
<dependency>
    <groupId>org.apache.hadoop</groupId>
    <artifactId>hadoop-hdfs</artifactId>
    <type>test-jar</type>
    <version>2.6.0</version>
    <scope>test</scope>
</dependency>

```

The code is reasonably simple, I'm creating the cluster in the Test setup and tearing it down during the teardown phase of the tests

```java
private MiniDFSCluster cluster;
private String hdfsURI;

public void setUp() throws Exception {
    super.setUp();
    Configuration conf = new Configuration();
    File baseDir = new File("./target/hdfs/").getAbsoluteFile();
    FileUtil.fullyDelete(baseDir);
    conf.set(MiniDFSCluster.HDFS_MINIDFS_BASEDIR, baseDir.getAbsolutePath());
    MiniDFSCluster.Builder builder = new MiniDFSCluster.Builder(conf);
    cluster = builder.build();
    hdfsURI = "hdfs://localhost:"+ cluster.getNameNodePort() + "/";
}

public void tearDown() throws Exception {
    cluster.shutdown();
}
```

This makes a cluster available for the tests, in this case its a simple log entry which is going to return the path to the log entry, because this has a guid in I need to just make sure the file is created starting as expected

```java
public void testCreateLogEntry() throws Exception {
	String logentry = new LogEntry().createLogEntry("TestStage", "TestCategory", "/testpath", cluster.getFileSystem());
	String date = new SimpleDateFormat("yyyyMMdd").format(new Date());
	assertTrue(logentry.startsWith(String.format("/testpath/TestStage_%s_", date)));
}
```
