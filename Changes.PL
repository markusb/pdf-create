#!/usr/bin/perl -w
#
# Changes.PL
#
# Create the 'Changes' file automatically from git commit messages
# and versioning tags in the repository

use strict;

open(OUT, ">Changes") or die "Can not open 'Changes' for writing\n";
open(IN,"git log --abbrev-commit --pretty |") or die "Can not run git\n";
while(<IN>){
  # read the change log
  if (/^commit /) {
    chop;
    # for each commit get the version from git
    my $sha=(split(/ /,$_,2))[1];
       $sha =~ s/\.\.\.$//;
    my $vers = `git name-rev --tags $sha 2>/dev/null`;
       $vers =~ s/^.*\///;
       $vers =~ s/~.*$//;
    print OUT "commit $sha...   PDF::Create $vers";
  } else {
    print OUT;
  }
}

