---
layout: post
author: Owen Rumney
title: Adventures with Spark, part two
tags: [spark, scala]
categories: [Programming, Spark]
---

Some time ago, back in September, I wrote a post on [starting my adventures with Spark]({% post_url 2014-09-14-Adventures_with_Spark_pt1 %}) but didn't progress things very far.

On thing that was holding me back was a reasonably real world problem to use as a learning case. I recently came across a question which seemed like a good starting point and for the last few evenings I have been working on a solution.

### The problem

A credit card company is receiving transaction data from around the world and needs to be able to spot fraudulent usage from the transactions.

To simplify this use case, I'm going to pick one fabricated indicator of fraudulent usage and focus on that.

- An alert must be raised if a credit card makes £10,000 of purchases within a 10 minute sliding window

For the purposes of this learning project I am going to assume the following this;

- There is a high volume of transactions
- No data needs to be retained
- Once an alert has been raised, a black box system will react to it

### The solution

From the outset, this problem seems perfectly suited to Spark Streaming and with the high volume its going to need a queue to manage the incoming transaction data.

I'm going to create a basic producer to pump transactions into Kafka to simulate the inbound transactions.

I don't want to detail the process of install Kafka and getting Spark set up, I'm using a Macbook and used brew to get everything installed and I'm using SBT for the solution [which can be found on github](http://github.com/owenrumney/fraud_detector).

Step 1: - Start the zookeeper for Kafka

```text

# in my case $KAFKA_HOME = /usr/local/Cellar/kafka_2.10-0.8.1.1/
cd $KAFKA_HOME
./bin/zookeeper-server-start.sh config/zookeeper.properties

```

Step 2: - Start the Kafka server

```text

cd $KAFKA_HOME
./bin/kafka-server-start.sh $KAFKA_HOME/config/server.properties

```

Step 3: Create the Kafka topic

```text

cd $KAFKA_HOME
./bin/kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor 1 --partitions 1 --topic kafka_queue

```

Step 4: Create a Scala project - I am going to use [IntelliJ IDEA](http://www.jetbrains.com/idea) because it's what I know.

Step 5: Add dependencies to the `build.sbt` file

```scala

name := "sparkStreaming_kafka"

version := "1.0"

scalaVersion := "2.10.4"

libraryDependencies += "org.apache.spark" % "spark-core_2.10" % "1.1.1"

libraryDependencies += "org.apache.spark" % "spark-streaming_2.10" % "1.1.1"

libraryDependencies += "org.apache.spark" % "spark-streaming-kafka_2.10" % "1.1.1"

libraryDependencies += "org.apache.kafka" % "kafka_2.10" % "0.8.1.1"

```

Step 6: Creating the transaction generator

```scala

class TransactionGenerator(noOfCards: Int) {
  import java.util.{Calendar, Properties}
  import kafka.javaapi.producer.Producer
  import kafka.producer.{KeyedMessage, ProducerConfig}
  import scala.util.Random

  private def generateCardNumber: String = {
    val sb = new StringBuilder(16)
    for (i <- 0 until 16) {
      sb.append(Random.nextInt(10).toString)
    }
    return sb.toString
  }

  val cards = for (i <- 0 until noOfCards) yield generateCardNumber

  def start(rate: Int): Unit = {
    val props = new Properties()
    props.put("metadata.broker.list", "localhost:9092");
    props.put("serializer.class", "kafka.serializer.StringEncoder");
    props.put("request.required.acks", "1");
    val config = new ProducerConfig(props)

    val producer = new Producer[String, String](config)

    while (true) {
      Thread.sleep(rate)
      val now = Calendar.getInstance.getTime.toString
      val card = cards(Random.nextInt(cards.length))
      val amount = Random.nextDouble() * 1000
      val message = new KeyedMessage[String, String]("kafka_queue", f"$now%s\t$card%s\t$amount%1.2f")
      producer.send(message)
    }
  }
}

```

Step 7: Driving the generator

```scala

object program {
  def main(args: Array[String]): Unit = {
  	// how many transactions to create a second and for how many cards
    val transPerSec = 5
    val cards = 200
    val tranGen = new TransactionGenerator(cards)
    // start the generator
    tranGen.start(1000/transPerSec)
  }
}

```

Step 8: The fraud alerting service

```scala

package com.owenrumney.sparkstreaming

import org.apache.spark.streaming.dstream.ReceiverInputDStream
import org.apache.spark.streaming.kafka.KafkaUtils
import org.apache.spark.streaming.{Minutes, Seconds, StreamingContext}

case class Transaction(date: String, cardNo: String, amount: Double)
case class Alert(cardNo: String, message: String)

class FraudAlertingService extends Serializable {

  def alert(alert: Alert): Unit = {
    println("%s: %s".format(alert.cardNo, alert.message))
  }
  def start() {
    val stream = new StreamingContext("local[2]", "TestObject", Seconds(10))
    val kafkaMessages: ReceiverInputDStream[(String, String)] =
      KafkaUtils.createStream(stream, "localhost:2181", "1", Map("kafka_queue" -> 1))

    kafkaMessages.window(Minutes(10), Seconds(10)).foreachRDD(rdd => rdd.map(record => {
      val components = record._2.split("\t")
      Transaction(components(0), components(1), components(2).toDouble)
    }).groupBy(transaction => transaction.cardNo)
      .map(groupedTransaction =>
      (groupedTransaction._1, groupedTransaction._2.map(transaction => transaction.amount).sum))
      .filter(m => m._2 > 10000)
      .foreach(t => alert(Alert(t._1, "Transaction amount exceed"))))

    stream.start()
    stream.awaitTermination()
  }
}

```

Step 9:

```scala

import org.apache.log4j.Logger

object spark_program {
  def main(args: Array[String]): Unit = {
    Logger.getRootLogger.setLevel(org.apache.log4j.Level.ERROR)
    val faService = new FraudAlertingService
    faService.start()
  }

```

So thats it, we'll get a printed alert when the service picks up a card with over £10k in 10 minutes.

I know that the code isn't great - I'm still working out Scala, so I will be improving on it where I can. My next post on the subject will be moving to a cloud implementation running over multiple node cluster to see what I can learn from that.
