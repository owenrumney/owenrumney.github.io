---
layout: post
title: Testing private methods with ScalaTest
description: How to test private methods easily with ScalaTest and PrivateMethodTester
tags: [scalatest, scala, testing]
categories: [Programming]
---

## Overview

As part of my journey into using Scala I have had to get used to the ScalaTest and the wealth of functionality it offers. 

One of the enduring headaches with unit testing is find a clean way to test private methods without being left feeling that you've somehow compromised the solution in order to fully test.



## Example
I've used an example which is reasonably common so easy to see the usefulness of the [`PrivateMethodTester`](http://doc.scalatest.org/3.0.1/#org.scalatest.PrivateMethodTester) trait. 

The example is that of a file loader where the source might be local, or S3 or similar. In this case, I'm going to have a public method on my `ObjectWithPrivate` scala object, this method will accept a `String` for the sourcePath to a file that I want to load the content of as a `BufferedSource`.

The sourcePath may be local, or it may be S3, but as the consumer I don't really want to care. The logical thing in this situation is to have the implementation details of loading the file hidden in private methods. These methods will attempt to load the file from their respective sources and throw a `FileNotFoundException` if it isn't available.


```scala
import org.slf4j.{Logger, LoggerFactory}
import scala.io.{BufferedSource, Source}
import scala.reflect.io.File

object ObjectWithPrivate {

  val logger: Logger = LoggerFactory.getLogger("ObjectWithPrivate")

  def loadFromPath(sourcePath: String): BufferedSource = {
    sourcePath match {
      case s if s.startsWith("s3") => loadFromS3(sourcePath)
      case _                       => loadFromLocal(sourcePath)
    }
  }

  private def loadFromS3(sourcePath: String, s3Client: AmazonS3 
                                            = AmazonS3ClientBuilder.defaultClient()): BufferedSource = {
    val uri: AmazonS3URI = new AmazonS3URI(sourcePath)
    try {
      val s3Object: S3Object = s3Client.getObject(uri.getBucket, uri.getKey)
      Source.fromInputStream(s3Object.getObjectContent)
    } catch {
      case aex: AmazonServiceException => {
        if (aex.getStatusCode == 404) {
          throw new FileNotFoundException(s"file not found: $sourcePath")
        }
        throw aex
      }
    }
  }

  private def loadFromLocal(sourcePath: String) = {
    logger.info(s"Loading config from local File: $sourcePath")
    if (!File(sourcePath).exists) {
      throw new FileNotFoundException(s"Config file not found: $sourcePath")
    }
    val bufferedSource = Source.fromFile(sourcePath)
    bufferedSource
  }

}
```

The difficulty now comes in testing the private methods. Testing local load can be done by calling the public `loadFromPath` method, but that won't work with the `loadFromS3` method as this needs the S3 Mocking to adaquetely test without requiring connectivity to S3 and a known file guaranteed to be present.

This is where the `PrivateMethodTester` trait comes in. By mixing this trait into our `ScalaTest` class, we can invoke a private method on our object. I've included the whole test class because it has all the set up of the S3 Mock (I see little point in creating an example that calls S3 then not include the required information on how to replicate.)

``` scala
import com.amazonaws.auth.{AWSStaticCredentialsProvider, AnonymousAWSCredentials}
import com.amazonaws.client.builder.AwsClientBuilder
import com.amazonaws.services.s3.AmazonS3ClientBuilder
import io.findify.s3mock.S3Mock
import org.scalatest.Matchers._
import org.scalatest.{BeforeAndAfterAll, BeforeAndAfterEach, FunSuite, PrivateMethodTester}

import scala.io.BufferedSource

class ObjectWithPrivateTest extends FunSuite with BeforeAndAfterEach with BeforeAndAfterAll with PrivateMethodTester {

  val endpoint: AwsClientBuilder.EndpointConfiguration = new AwsClientBuilder.EndpointConfiguration(
      "http://localhost:8001",
      "eu-west-1"
    )
  val credentials = new AWSStaticCredentialsProvider(new AnonymousAWSCredentials)
  val api: S3Mock = new S3Mock.Builder()
                        .withPort(8001)
                        .withInMemoryBackend.build
  api.start

  override def beforeEach() {
    val client = AmazonS3ClientBuilder.standard
      .withPathStyleAccessEnabled(true)
      .withEndpointConfiguration(endpoint)
      .withCredentials(credentials)
      .build
    client.createBucket("testbucket")
    client.putObject("testbucket", "files/file1", "file1_content")
  }

  override def afterAll() {
    api.stop
  }

  test("ObjectWithPrivate loads a test file from S3") {
    val client = AmazonS3ClientBuilder.standard
      .withPathStyleAccessEnabled(true)
      .withEndpointConfiguration(endpoint)
      .withCredentials(credentials)
      .build

    val loadFromS3 = PrivateMethod[BufferedSource]('loadFromS3)
    val content = ObjectWithPrivate invokePrivate loadFromS3(
      "s3://testbucket/files/file1",
      client
    )
    content.mkString shouldBe "file1_content"
  }
}

// further tests for local omitted

```

In the test, the key part is the following line;

```scala
val loadFromS3 = PrivateMethod[BufferedSource]('loadFromS3)
```

This creates a `PrivateMethod` object which will return a `BufferedSource` which we pass the name of the method to be called as a `Symbol`. One of the features added by the `PrivateMethodTester` is the `invokePrivate` method such that we can use it to call the private method on a given Object (or instance of a class for that matter)

```scala
val content = ObjectWithPrivate invokePrivate loadFromS3(
  "s3://testbucket/files/file1",
  client
)
```

This will call the private method, returning our `BufferedSource` and I can test that the content of the mocked S3 object is infact `file1_content`.

For interest, here is the `build.sbt` for this simple project

```scala
name := "PrivateMethodTester"

version := "0.1"

scalaVersion := "2.12.8"

// dependencies versions
val amazonSdkVersion = "1.11.540"
val logbackClassicVersion = "1.2.3"
val s3MockVersion = "0.2.4"
val scalaTestVersion = "3.0.5"
val slf4jVersion = "1.7.25"

libraryDependencies ++= Seq(
  "com.amazonaws" % "aws-java-sdk-core" % amazonSdkVersion,
  "com.amazonaws" % "aws-java-sdk-s3" % amazonSdkVersion,
  "org.slf4j" % "slf4j-api" % slf4jVersion,
  "ch.qos.logback" % "logback-classic" % logbackClassicVersion,
  "org.scalatest" %% "scalatest" % scalaTestVersion,
  "io.findify" %% "s3mock" % s3MockVersion % Test
)
```

### Update - Implicit Parameters

One thing worth adding is what to do when you have a method that takes an implicit method which needs testing. Lets used this contrived example;