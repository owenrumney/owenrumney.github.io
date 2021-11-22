---
layout: post
author: Owen Rumney
title: Generating test data with Faker
description: Using faker in python to generate test data that is reasonably meaningful
tags: [python, faker, test data, generator]
categories: [Programming]
---
Python is one of those languages where if you can concieve it, there is probably already a library for it. 

One great library is Faker - this makes the generation of sensible test data much easier and removes a lot of the issues around having to using unrealistic junk values when creating it on your own.

There is lots to see, and your probably best off [reading the docs](https://faker.readthedocs.io/en/master/index.html), but this is to give you an overview.

## Installation

Installation is simple, just use pip to install;

```python
pip install faker
```

## Usage

Now that you have it installed, you can use python REPL or [ptpython](https://github.com/prompt-toolkit/ptpython) to have a play.

### Some basics

```python
from faker import Factory

fake = Factory.create()
fake.first_name(), fake.last_name(), fake.email()
```

This will give you a tuple with a random name and email;

```shell 
('Mary', 'Bennett', 'jamesrodriguez@hotmail.com')
```

### Localisation
If you want to get UK post codes, you can tell the factory a localisation to use when generating the data;

```python
from faker import Factory

fake = Factory.create('en_GB')

fake.street_address(), fake.postcode()
```

which will yield;

```shell
('Studio 54\nCollins fork', 'L2 7XP')
```

### Synchronising Multiple Fakes

Everytime you call a method on the `fake` object you get a new value. If you wanted to synchronise two `fake` objects you can use the seed. This will mean that the each consecutive call from each `fake` will return the same value.

This is probably more easily demonstrated in code;

```python
from faker import Factory

fake1 = Factory.create()
fake2 = Factory.create()

fake1.seed(12345)
fake2.seed_instance(12345)

fake1.name(), fake2.name()
fake1.name(), fake2.name()
```

This will result in a tuple containing the same name across synchronised `fake` objects.

```shell
('Adam Bryan', 'Adam Bryan')
('Jacob Lee', 'Jacob Lee')
```

### Making it a bit more interesting

In a previous pose I fiddled with credit card data where I created test data. Faker can be used to help out here. The code below isn't an example of amazing Python, its just simple code to show it working.


First, we bring in the imports that are going to be used;
```python
import csv
import random
from faker import Factory
from faker.providers import credit_card
```

Some helper methods, these are just to keep things clean

```python
def get_transaction_amount():
    return round(random.randint(1, 1000) * random.random(), 2)

def get_transaction_date(fake):
    return fake.date_time_between(start_date='-30y', end_date='now').isoformat()
```

Some more helpers for the creation of records for our customer and transaction

```python
def create_customer_record(customer_id):
    fake = Factory.create('en_GB')
    return [customer_id, fake.first_name(), fake.last_name(), fake.street_address().replace('\n', ', '), fake.city(), fake.postcode(), fake.email()]

def create_financials_record(customer_id):
    fake = Factory.create('en_GB')
    return [customer_id, fake.credit_card_number(), get_transaction_amount(), get_transaction_date(fake)]
```

A helper function to save the records to file
```python
def flush_records(records, filename):
    with open(filename, 'a') as file:
        csv_writer=csv.writer(file, delimiter = ',', quotechar = '"', quoting = csv.QUOTE_MINIMAL)
        for record in records:
            csv_writer.writerow(record)
    records.clear()
```

Finally the main calling block to create the records
```python
def create_customer_files(customer_count=100):
    customer_records = []
    financial_records = []
    for id in range(1, customer_count):
        customer_id = str(id).zfill(10)
        customer_records.append(create_customer_record(customer_id))
        financial_records.append(create_financials_record(customer_id))
        if len(customer_records) == 100:
            flush_records(customer_records, 'customer.csv')
            flush_records(financial_records, 'financials.csv')
    flush_records(customer_records, 'customer.csv')
    flush_records(financial_records, 'financials.csv')

create_customer_files()
```

Once we run this, we'll have 2 files with customer details and a credit card transaction.

Customer records
```shell
0000000001,Clifford,Turner,"Flat 17, Smith crescent",Johnsonborough,DN5 7JJ,ucooper@gmail.com
0000000002,Amy,Clements,"Studio 96s, Anne harbor",Maureenfurt,LA53 8HZ,marshalllee@williams-hart.info
0000000003,Robin,Sinclair,5 Lesley motorway,Bryanbury,E2 9EU,sheilawhitehead@miles.com
```

Financial records
```shell
0000000001,4851450166907,179.28,2009-06-01T07:03:43
0000000002,370196022599953,229.46,2017-12-11T10:14:59
0000000003,4285121047016,10.61,1995-04-23T23:54:19
```

By sharing the customer ID across both files we have some semblence of referential integrity.

This code only creates a single transaction per customer, it can be easily modified to create multiple transactions by adjusting the `create_financial_records` to take an optional argument of `transaction_count=1` and updating the `append` to handle an array of arrays
```

