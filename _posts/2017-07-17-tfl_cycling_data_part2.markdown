---
layout: post
author: Owen Rumney
title: TFL Cycling DataSet - Part 2
tags: [python, programming, spark, learning, datasets]
categories: [Spark, Programming]
---

Following on from [part 1]({% post_url 2017-07-16-tfl_cycling_data_part1 %}) of this mini series. I've got my local environment ready to go and I have pulled down some test data to work with.

The next step is to start having a look at some of the data.

## Loading in the data

We know that the data is in `csv` format so can use the Spark `read` functionality to bring it in. With the single file in this local environment it's a case of;

```python
data = spark.read.csv('01aJourneyDataExtract10Jan16-23Jan16.csv', header=True, inferSchema=True)
for col in data.columns:
    data = data.withColumnRenamed( col, col.replace(" ", ""))
```

This line will create a `DataFrame` called data and load the csv input into it. By setting `header` to `True` we are saying that the first row of the data is a header row.

`inferSchema` will ask Spark to have a go at working out the correct types for the columns that are being brought in.

## Quick Cleanup

Even though `inferSchema` was used, if we call `data.describe()` we can see that the type of the dates is `string`. I'm going to put that down to the fact that these dates are in UK format.

```
DataFrame[description: string
, RentalId: string
, Duration: string
, BikeId: string
, EndDate: string
, EndStationId: string
, EndStationName: string
, StartDate: string
, StartStationId: string
, StartStationName: string]
```

I think I'm going to want these to be dates later on, so I'm going to convert them to `timestamps` now.

```python
from pyspark.sql.functions import unix_timestamp
dated_data = data.select('RentalId' \
           ,unix_timestamp('StartDate', 'dd/MM/yyyy HH:mm').cast("double").cast("timestamp").alias('StartDate') \
           ,unix_timestamp('EndDate', 'dd/MM/yyyy HH:mm').cast("double").cast("timestamp").alias('EndDate') \
           ,'Duration' \
           ,'StartStationId' \
           ,'EndStationId')
```

This block uses the `unix_timestamp` function to get the long number representation of the date which we can then turn into the timstamp type. By passing the format of the date we can solve the issue of it being in a format that the `inferSchema` wasn't expecting. I've used `.alias()` to specify the name of the derived column.

## Getting the StationId Data

There is an API which we can use to get the additional data for the `StartStation_Id` and `EndStation_Id`. This can be found [here](https://api.tfl.gov.uk/swagger/ui/index.html?url=/swagger/docs/v1#!/BikePoint/BikePoint_Get) on the TfL website.

We need a list of all the start and end bike point/stations that are in the dataset so I went for doing a `union` to get this.

```python
stationids = sorted((data.select('StartStationId') \
                    .union(data.select('EndStationId'))) \
                    .rdd.map(lambda r: r[0]) \
                    .distinct() \
                    .collect())
```

This will return us a sorted list of all the Ids in the dataset which can be passed into a helper method which will call into the API mentioned about.

```python
def get_bike_points(points_ids):
    bike_point_file = '~/datasets/cycling/bike_points.csv'
    base_url = 'https://api.tfl.gov.uk/BikePoint/BikePoints_'

    with open(bike_point_file, 'w') as csvfile:
        fieldnames = ['pointId', 'commonName', 'lat', 'lon', 'placeType', 'properties']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        for point in points_ids:
            if point == None:
                continue
            url = "%s%s" % (base_url, point)
            req = requests.get(url)
            if req.status_code != 200:
                writer.writerow({"pointId": point, "commonName": "Not Found"})
            else:
                bike_point = json.loads(req.text)
                props = {}
                if bike_point.has_key('additionalProperties'):
                    for p in bike_point['additionalProperties']:
                        props[p['key']] = p['value']
                writer.writerow({"pointId": point, "commonName": bike_point['commonName'], "lat": bike_point['lat'], \
                                "lon": bike_point['lon'], "placeType": bike_point['placeType'], 'properties': props})
        csvfile.flush
```

This block takes the list of `Id` and collects the data for the bike station, extracts what is wanted from the returned dataset then saves it into a csv file.

### Cleaning up the StationId data

Some of the stations in the dataset aren't there anymore so we get a `404` when we hit the page. To get round this I've just created a line for the ID with a common name of not found.

That said, we do have this information in the original data set, so a bit of fiddling can be used to update the `bike_points` data with the correct `commonName`.

```python
bike_points = spark.read.csv('bike_points.csv', header=True, inferSchema=True)

combined_bike_points = bike_points.where(bike_points.commonName == "Not Found") \
                      .join(data, data.StartStationId == bike_points.pointId)\
                      .select(bike_points.pointId \
                            , data.StartStationName.alias("commonName") \
                            , bike_points.lat \
                            , bike_points.lon \
                            , bike_points.placeType \
                            , bike_points.properties) \
                      .distinct()

bike_points = combined_bike_points \
              .union(bike_points \
                     .where(bike_points.commonName <> "Not Found"))
```

Okay, long winded but we now have the station data to work with too.
