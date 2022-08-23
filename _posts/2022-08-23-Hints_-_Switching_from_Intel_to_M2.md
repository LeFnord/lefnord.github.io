---
layout: post
title: Hints … Switching from Intel to M2
excerpt: ''
date: 2022-08-23 22:07 +0200
modified: 2022-08-23 22:07 +0200
tags: [hints]
comments: false
share: false
author: LeFnord
---

Yeah my new MBP 13" M2 arrived yesterday. And I had to migrate from my old Intel one.

Here some lessons that I learned.

## Brew

on your old machine do:

- save your delevopment data, like PG databases
- list all installed formulaes and save it
- remove Brew completely with
```shell
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/uninstall.sh)"
```

on your new machine:

- ensure you have the xcode command line tools installed
- install brew, see above, but now `install.sh`
- reinstall your packages from above list  
  or doing a kind of cleaning up, then install only base packages like 'redis'
