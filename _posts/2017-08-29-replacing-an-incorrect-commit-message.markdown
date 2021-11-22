---
layout: post
author: Owen Rumney
title: Replacing an incorrect git commit message
tags: [git, programming]
categories: [Git]
---

If you have committed some code to git (or in the current case, BitBucket) and you have made an error in the commit message (in the current case, referenced the wrong Jira ticket), all is not lost.

To replace the commit message perform the following actions.

```
git commit -amend
```

Change the commit message, in my case;

```
FOO-1234 - fix the bar
 - add some stuff
```

to

```
FOO-1235 - fix the bar
 - add some stuff
```

Then all that is required is to do a `push` with `--force`

```
git push --force
```
