#!/usr/bin/perl -w
#
# Changes.PL
#
# Create the 'Changes' file automatically from git commit messages
# and versioning tags in the repository.
#
# This script is designed to be run only on the PDF::Create maintainers
# workstation and is not needed to install PDF::Create.
#

use strict;

#
# Bail out with non-alarming error message if git or the correct repository
# is missing.
#

my $user;
my $git=`which git`;
chomp $git;
if (! (-f $git)) {
  printf "Skipping... (git not found/installed)\n";
  exit (0);
}

if (! ($user=`git config --get user.name 2>/dev/null`)) {
  printf "Skipping... (git not found/installed)\n";
  exit (0);
}
chop $user;
if ("$user" ne "Markus Baertschi") {
  printf "Skipping... (not on maintainers workstation)\n";
  exit (0);
}

open(OUT,">Changes") or die "Can not open 'Changes' for writing\n";
open(IN,"git log --abbrev-commit --pretty |") or die "Problem running git log\n";
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
    print "commit $sha...   PDF::Create $vers";
  } else {
    print;
  }
}

