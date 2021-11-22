---
layout: post
title: "Building Jekyll Websites with Travis"
date: 2020-10-04 00:00:00
image: '/assets/img/blog-author.png'
description: How to generate your Jekyll website with Travis
tags: [travis, jekyll, blogging]
categories:
twitter_text: Generating your Jekyll website with Travis
---

This website is generated using [Jekyll](https://jekyllrb.com/), a static site generator. Basically, I write the posts as Markdown files, run it through Jekyll and out pops this website, [owenrumney.co.uk]('https://www.owenrumney.co.uk').

For as long as I have been building the site in this way I've built the site locally and commited the contents in to my [Github Pages Project](https://github.com/owenrumney/owenrumney.github.io). This step has always been a bit tedious, ensuring that I build the site to the correct folder with the `.git` references setup and up to date isn't difficult, just a pain.

At work we use Travis extensively for our build pipeline, I already have a Travis account personally so it occurred to me that I should be generating the site directly off commits to the blog base project, where I write my Markdown.

## What I will need
- Travis Account
- `GITHUB_TOKEN` with permissions to update repositories
- Travis gem
- Build Scripts
- `Makefile`
- `.travis.yml` file

### The Travis Account

A travis account is required to be able to do the builds, for more information see the [Travis website](https://www.travis.com).

### The `GITHUB_TOKEN`

The github token allows processes to access your github account and perform the actions that the token has been permissioned to perform. To create a new `GITHUB_TOKEN` you can navigate to the [Generate New Token page](https://github.com/settings/tokens/new) in you logged in Github account.

For this, I created a token that had access to commit to repos. Its sensible to have specific tokens for specific tasks in my opinion - rather than one super token that you use everywhere.

### The Travis Gem

We are going to be encrypting the `GITHUB_TOKEN` into the `.travis.yml` file, so we need the `travis` gem to perform this. To install run
```
gem install travis
```

If you've got Jekyll, I'm assuming you've already got the Ruby infrastructure on your machine.

### The Build Scripts

Below is the build script I use; I'll break down the sections.

```shell
#! /bin/bash

set -e

DEPLOY_REPO="https://${GITHUB_TOKEN}@github.com/owenrumney/owenrumney.github.io.git"
MESSAGE=$(git log -1 HEAD --pretty=format:%s)

function clean { 
	echo "cleaning _site folder"
	if [ -d "_site" ]; then rm -Rf _site; fi 
}

function clone_site { 
	echo "getting latest site"
	git clone --depth 1 $DEPLOY_REPO _site 
}

function build { 
	echo "building site"
	bundle exec jekyll build --lsi
}

function deploy {
	echo "deploying changes"

	if [ -z "$TRAVIS_PULL_REQUEST" ]; then
	    echo "except don't publish site for pull requests"
	    exit 0
	fi  

	if [ "$TRAVIS_BRANCH" != "master" ]; then
	    echo "except we should only publish the master branch. stopping here"
	    exit 0
	fi

	cd _site
	git config user.name "Travis Build"
    git config user.email travis@owenrumney.co.uk
	git add -A
	git commit -m "Travis Build: ${TRAVIS_BUILD_NUMBER}. ${MESSAGE}"
	git push $DEPLOY_REPO master:master
}
```

#### clean

The `clean` function ensures that the location the static site is generated into is gone (in the default cause this is the `_site` folder)

#### clone_site

When we do the build in travis, we need to have the destination `github pages` project cloned into `_site` for writing. THis function does that clone to get the latest.

#### build

The `build` function runs `jekyll build` which by default will generate the site into `_site` folder

#### deploy

The `deploy` function is the main section for commiting the updates in the `github pages` project. This function ensures that the Travis run isn't a PR and that the branch is `master` if these conditions are satisfied it will commit the changes to `_site` and push to make them available.

### The Makefile
To simplify the running of the commands - and to allow them to be used locally easily, there is a `Makefile`

```make
.PHONY: initpost clean clone_site build deploy

initpost:
	@bash -c "./scripts/initpost.sh"

clean:
	@bash -c ". scripts/build.sh && clean"

clone_site:
	@bash -c ". scripts/build.sh && clone_site"

build: clean clone_site
	@bash -c ". scripts/build.sh && build"

deploy: build
	@bash -c ". scripts/build.sh && deploy"

```

Running `deploy` target will automatically run the `build` target, which in turn runs the `clean` and the `clone_site`. Now to build the site we can simply run
```
make build
```

### The `.travis.yml` file
To pull this all together and trigger the build when we commit, we need the `.travis.yml` file. 

This file sits in the root of the project and when committed, triggers a Travis build of the current branch and where applicable, the associated PR.

```ruby
language: ruby
cache: bundler
env:
  global:
    secure: dsfojisdfglksdhgflsdhgsdfghedlfs
install:
- bundle install
script:
- "make deploy"

```

This is a fairly straight forward `.travis.yml` file. We are telling Travis that this project is `ruby` based and we need to have the bundler cache available. 

Before starting, we want to install all of the required dependencies from the `Gemfile`, in this case it is basically `jekyll` and the ohter `jekyll` plugins I use in this site.

One interesting part is the `env/global/secure` section. This contains my `GITHUB_TOKEN` in an encrypted form. To generate this, from the root of the project use the `travis` gem installed previously....

```
travis encrypt GITHUB_TOKEN=abcdefghij1234 --add
```

This will prompt to ask if you want to create the ENVVAR in the current folders `.travis.yml` file. It used the details of the repo as a seed for encryption.


Finally the job runs `make deploy` which will build the site and deploy it to the `github pages` project as a new commit.

## The Travis Output

Now, when I commit changes to my blog base project, it runs in Travis and I get output similar to this;

```shell
Installing SSH key from: default repository key
Using /home/travis/.netrc to clone repository.
git.checkout
$ git clone --depth=50 --branch=master https://github.com/owenrumney/blogbase.git owenrumney/blogbase

Setting environment variables from .travis.yml
$ export GITHUB_TOKEN=[secure]
rvm
$ rvm use default
$ export BUNDLE_GEMFILE=$PWD/Gemfile
cache.1
Setting up build cache
cache.bundler
adding /home/travis/build/owenrumney/blogbase/vendor/bundle to cache
ruby.versions
$ ruby --version
install

$ bundle install
$ make deploy

cleaning _site folder
getting latest site
Cloning into '_site'...
building site
Configuration file: /home/travis/build/owenrumney/blogbase/_config.yml
            Source: /home/travis/build/owenrumney/blogbase
       Destination: /home/travis/build/owenrumney/blogbase/_site
 Incremental build: disabled. Enable with --incremental
      Generating... 
                    done in 0.645 seconds.
 Auto-regeneration: disabled. Use --watch to enable.
deploying changes
[master a1e2f08] Travis Build: 6. Update the build script to use the Makefile
 1 file changed, 2 insertions(+), 2 deletions(-)
To https://github.com/owenrumney/owenrumney.github.io.git
   5f492f6..a1e2f08  master -> master
The command "make deploy" exited with 0.
cache.2
store build cache
Done. Your build exited with 0.
```
