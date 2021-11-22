---
layout: post
author: Owen Rumney
title: Argument defaults in shell scripts
tags: [shell, bash, scripting]
categories: [SysAdmin]
---

Regularly when writing a shell script I find that I want to be able to pass an argument into the script but only sometimes. For example if I want the script to output to `/tmp` folder for the most part but I'd like the opportunity to select the output myself.

Default arguments can be used in scripts using the following simple syntax

```shell
#!/bin/sh

# example script to write to output folder

OUTPUT_PATH=${1:-/tmp/output}

echo "some arbitrary process" > ${OUTPUT_PATH}/arbitrary_output.output

```

This will either used the first parameter passed in for the output path or a default value of `/tmp/output` if that isn't provided

```Shell
sh example_script.sh # outputs to /tmp/output

sh example_script.sh /var/tmp/special # outputs to /var/tmp/special
```
