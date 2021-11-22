---
layout: post
author: Owen Rumney
title: Introducing gitsearch-cli
description: Description of a tool I've written that can be used to find github projects from the command line
tags: [python3, github, pypi]
categories: [Git, Programming]
---
The first version of gitsearch-cli is now available. This command line interface allows you to search github repositories and users using keywords and (currently) a handful of additional criteria.

## Installation
To install git search you can use `pip3` with the following command;

```shell
pip3 install gitsearch-cli
```

## Usage
By default the search will be scoped to look in repositories, however you can change the scope to look specifically for users.

For additional help, just use;

```Shell
git-search --help
```

### Searching for Users
```shell
git-search --scope=users owen rumney

or

git-search --scope=users owenrumney
```

This will yield the following results;

| username   | url                           |
| :--------- | :---------------------------- |
| owenrumney | https://github.com/owenrumney |

### Searching for repositories
When searching for repositories you can create a general search by keyword or focus the search by including the language and/or user.

```shell
git-search -l=scala -u=apache spark
```
This will give the following result;

| name          | owner  | url                                     |
| :------------ | :----- | :-------------------------------------- |
| fluo-muchos   | apache | https://github.com/apache/fluo-muchos   |
| predictionio  | apache | https://github.com/apache/predictionio  |
| spark         | apache | https://github.com/apache/spark         |
| spark-website | apache | https://github.com/apache/spark-website |

If you want to only return results where the keyword is in the name, you can use the `--nameonly` flag

```shell
git-search -l=scala -u=apache spark --nameonly
```
This will give the following result;

| name          | owner  | url                                     |
| :------------ | :----- | :-------------------------------------- |
| spark         | apache | https://github.com/apache/spark         |
| spark-website | apache | https://github.com/apache/spark-website |

## TODO
- [ ] Add date based options for search criteria
- [ ] Refactor the code to be more pythonic
