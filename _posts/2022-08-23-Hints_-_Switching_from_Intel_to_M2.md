---
layout: post
title: Hints … Switching from Intel to M2
excerpt: ''
date: 2022-08-23 22:07 +0200
modified: 2022-09-01 22:07 +0200
tags: [hints]
comments: false
share: false
author: LeFnord
---

Yeah my new MBP 13" M2 arrived yesterday. And I had to migrate from my old Intel one.

Here some lessons that I learned.

## Brew

#### ⚠️ Do this only, if you don't need "legacy" apps.

What do I mean: In my case, I need use rbenv to manage my rubys,
in one project an oracle access is required, will be done with `ruby-oci8`. This gems needs the Oracle Instantclient, but this one is only for Mac Intel available.

on your old machine do:

- save your delevopment data, like PG databases
- list all installed formulaes and save the *Brewfile* with
```shell
brew bundle dump
```
- remove Brew completely with
```shell
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/uninstall.sh)"
```

on your new machine:

- ensure you have the xcode command line tools installed
- install brew, see above, but now `install.sh`
- reinstall your formulas with
```shell
brew bundle
```

#### I did it … 🤬

to fix it  had to do following steps

1. go in *Finder* to the *Termninal* and open "Information" (⌘+i)
2. check "open with Rosetta" (or similar)
3. install homebrew but now with given architecture
```shell
arch -x86_64 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
```
4. and reinstall your formulas as above

How to use Mx Apps?

You have to create the folder structure under `/opt`, see here [Untar anywhere](https://docs.brew.sh/Installation#untar-anywhere)

And specify the architecture then, e.g.
```
arch -arm64 brew install tiles
```
or even better, create your own alias … 😉

… to be continued