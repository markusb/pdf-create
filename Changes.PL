#!/usr/bin/perl -w
#
# Changes.PL
#
# Create the 'Changes' file automatically from git commit messages'
#

use strict;

`git log --abbrev-commit --pretty > Changes`;

