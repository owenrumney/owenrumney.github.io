---
layout: post
author: Owen Rumney
title: CSV to Markdown table - Sublime Package
tags: [python, programming, sublime text]
---

Now I'm writing almost all documentation in markdown then using Pandoc to convert it to Mediawiki or docx as required, I needed to finds an easier way to quickly create my tables.

It doesn't do anything fancy, but I created a sublime package to do the conversion of a csv formatted table into a markdown table.

**Assumptions**

The following assumptions are made about the csv

- You've got headers in the first row
- Any empty cells are correctly formatted with commas
- You don't have any commas in the values

## Creating the Plugin

Creating a new Plugin with Sublime Text 3 is a case of `Tools -> Developer -> New Plugin`

This will create a new templated file in the User section.

```python
import sublime
import sublime_plugin


class CsvToMdCommand(sublime_plugin.TextCommand):

	content = ""

	def run(self, edit):
		for region in self.view.sel():
			if not region.empty():
					s = self.view.substr(region)
					self.process(s)
					self.view.replace(edit, region, self.content)
					self.content = ""

	def process_row(self, row, isHeader = False):
		self.content += ('|' + row.replace(',', '|') + '|' + '\n')
		if isHeader:
			self.content +=  '|' + ('-|' * (row.count(',') + 1) + '\n')


	def process(self, rows):
	    first = True
	    for row in rows.split("\n"):
	        self.process_row(row.strip(), first)
	        if first:
	            first = False
```

To add the `Command Palette` command, use a file with the extension `.sublime-commands` in the `Packages/User` folder

```json
[{ "caption": "CSV to MD: Convert", "command": "csv_to_md" }]
```
