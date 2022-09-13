---
layout: post
title: Introducing lazytrivy
date: 2022-09-07 00:00:00
image: '/assets/img/owen.png'
description: Using lazytrivy as a Trivy wrapper to simplify usage
tags: [scanning, tui, UI, golang, programming]
categories: [Scanning]
twitter_text: Scanning for vulnerabilities just got lazier
---

> UPDATED: updated 12th Sept 2022 to include Filesystem Scanning

#### View `lazytrivy` on [GitHub](https://github.com/owenrumney/lazytrivy){:target="_blank" }

![lazytrivy](https://github.com/owenrumney/lazytrivy/blob/master/.github/images/scan_all.png?raw=true)

[Trivy](https://trivy.dev) is the go to scanner for vulnerabilities and is rapidly becoming the go to for all your scanning needs.

lazytrivy just makes the experience even easier. You can run `lazytrivy` without remembering all the commands and get a quick summary of the vulnerabilities you have.

### Features

`lazytrivy` has a growing list of features; right now -

- Imag Scanning
  - Scan individual images on your machine
  - Scan all the images on your machine
  - Scan a remote image
- AWS Scanning
  - Scan your AWS account for misconfigurations
  - Dive into services and find service specific misconfigurations
- File System Scanning
  - Scan a local directory for misconfigurations, vulnerabilities and secrets

### Image Scanning

#### Individual Images

Choose an image from the side menu on the left and scan for vulnerbalities. 

![Scan an image](https://github.com/owenrumney/lazytrivy/blob/master/.github/images/scan_individual_images.gif?raw=true)


#### All Images

Alternative, you can scan all the images on the machine for a summary list that can be navigated through.

![All Image Scanning](https://github.com/owenrumney/lazytrivy/blob/master/.github/images/scan_all_images.gif?raw=true)


#### Remote Images

For images not on your machine, no problem - you can scan a remote image by pressing `r`

![Remote Image scanning](https://github.com/owenrumney/lazytrivy/blob/master/.github/images/scan_remote_image.gif?raw=true)

The image will be scanned without needing to take up storage on your machine. You still get the same detailed results.

#### Filtering 

In all cases, you can filter the results (`Critical`, `High`, `Medium`, `Low`, and `Unknown`) by pressing the first letter of the Severity letter... eg; `c` for `Critical`.

Pressing `Return` on the issues will show more information about the issue.,

### AWS Scanning

Quickly switch to AWS mode by pressing `w` and you can scan accounts. If you have not run previously, then you can press `s` to start a scan and `lazytrivy` will attempt to detect credentials to work with.

For this to work, you will need to have either `AWS` environment variables set or valid credentials in your `.aws` folder by using the `awscli`, `saml2aws` or similar.

![Scanning AWS](https://github.com/owenrumney/lazytrivy/blob/master/.github/images/scan_aws_account.gif?raw=true)

Scanning takes a short while depending on the size of the account, but eventually you will get a service list on the left that you can navigate through.

Selecting a service will show all the issues identified and you can drill into the AWS resources to see what the problems are.

Pressing `return` on the issues will show more information about the issue.

### File System Scanning

Switching to Filesystem mode using `w` and you can scan a local directory. 

Alternatively, you can start `lazytrivy` in file system mode using

```bash
lazytrivy fs /path/to/scan
```

![Scanning File System](https://github.com/owenrumney/lazytrivy/blob/master/.github/images/scan_filesystem.gif?raw=true)


### Issues, Comments, Suggestions

Comments, suggestions and issues are most welcome, please raise them in [GitHub](https://github.com/owenrumney/lazytrivy/issues)






