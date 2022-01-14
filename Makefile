
.PHONY: initpost
initpost:
	@bash -c "./scripts/initpost.sh"

.PHONY: install
install:
	bundle install

.PHONY: test
test: install
	bundle exec jekyll serve

