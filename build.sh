#! /bin/bash

set -e

DEPLOY_REPO="https://${GITHUB_TOKEN}@github.com/owenrumney/owenrumney.github.io.git"

function main {
	clean
	get_current_site
	build_site
    deploy
}

function clean { 
	echo "cleaning _site folder"
	if [ -d "_site" ]; then rm -Rf _site; fi 
}

function get_current_site { 
	echo "getting latest site"
	git clone --depth 1 $DEPLOY_REPO _site 
}

function build_site { 
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
	git config --global user.name "Travis Build"
    git config --global user.email travis@owenrumney.co.uk
	git add -A
	git status
	git commit -m "Built by Travis CI $TRAVIS_BUILD_NUMBER"
	git push $DEPLOY_REPO master:master
}

main