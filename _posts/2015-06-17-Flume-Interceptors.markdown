---
title: Writing a Flume Interceptor
layout: post
author: Owen Rumney
tags: [hadoop, flume, java]
categories: [Big Data, Programming]
---

Here we are in June, some five months since the last post and I finally have some time and content to sit and write a post.

In April 2013 I started working with Hadoop, the plan was to suck in server application logs to determine who was using what data within the business to make sure it was being correctly accounted for. At the time, Flume seemed like the obvious choice to ingest these files till we realised the timing, format and frequency made Flume a little like over kill. As it happened, it was discounted before I could get my teeth into it.

Two years later and there is a reason to use Flume - high volumes of regularly generated XML files which need ingesting into HDFS for processing - clearly a use case for Flume.

There are two key requirements for this piece, one that the file name be preserved somehow and that the content be converted to JSON inflight - for this post I'm going to focus only on the former.

When setting up the configuration for the Flume agent, the Spooling Directory Source can be configured to with `fileHeader = true` which will add the full path of the originating file into the header where it can be used by the interceptor. This can be appended to the destination path in HDFS, but as it contains the complete originating path it will go into a similar structure to source - in our case that isn't desirable.

To solve this, I'm writing and interceptor which will mutate the path to just have the filename with no extension.

Creating the inteceptor requires a number of steps;

1. Importing required dependencies;

```xml
<dependency>
    <groupId>org.apache.flume</groupId>
    <artifactId>flume-ng-core</artifactId>
    <version>1.5.0</version>
</dependency>
```

Then we need to create the abstract class which implements Interceptor which will be used as a base for future interceptors.

```java
public class AbstractFlumeInterceptor implements Interceptor {

    public void initialize() {    }

    public Event intercept(Event event) {
        return null;
    }

    public List<Event> intercept(List<Event> events) {
        for (Iterator<Event> eventIterator = events.iterator(); eventIterator.hasNext(); ) {
            Event next =  intercept(eventIterator.next());
            if(next == null) {
                eventIterator.remove();
            }
        }
        return events;
    }

    public void close() {    }
}
```

Now we have this class which wraps up the logic of handling a list of Events we need to create the concrete class called `FilenameInterceptor`

```java
@Override
public Event intercept(Event event) {
    Map<String, String> headers = event.getHeaders();
    String headerValue = headers.get(header); // header in this case is 'file' as per the config
    if(headerValue == null) {
        headerValue = "";
    }
    Path path = Paths.get(headerValue);
    if (path != null && path.getFileName() != null) {
        headerValue = FilenameUtils.removeExtension(path.getFileName().toString());
    }
    headers.put(header, headerValue);
    return event;
}
```

In the conf file for Flume we need the nested class in our Interceptor to build it, so the following Builder class is added

```java
public static class Builder implements Interceptor.Builder {
    private String headerkey = "HostTime";

    public Interceptor build() {
        return new FilenameInterceptor(headerkey);
    }

    public void configure(Context context) {
        headerkey = context.getString("key");
    }
}
```

Now we have all this we can `mvn clean package` and copy the jar to the lib folder - in my case we're using Cloudera so its in the parcels folder `/opt/cloudera/parcels/CDHxxx/flume-ng/lib`, from here it will be picked up with `flume-ng` starts.

The new additions to the conf file are;

```properties
# ... source1 props ...
agent1.sources.source1.fileHeader = true
agent1.sources.source1.interceptors = interceptor1
agent1.sources.source1.interceptors.interceptor1.type = [package].[for].[Interceptor].FilenameInterceptor$Builder
# ... hdfs1 props ...
agent1.sinks.hdfs1.filePrefix = %{file}
```
