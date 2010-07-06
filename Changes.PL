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
# is missing or not right.
#

my $user;
my $git=`which git`;
chomp $git;
if (! -x $git) {
  printf "Skipping... (git not found/installed)\n";
  exit (0);
}
if (! ($user=`git config --get user.name 2>/dev/null`)) {
  printf "Skipping... (git not found/installed or user.name not defined)\n";
  exit (0);
}
chop $user;
if ("$user" ne "Markus Baertschi") {
  printf "Skipping... (not on maintainers workstation)\n";
  exit (0);
}

#
# Read the git log and add version tab info
#
print "Creating Changes file from git commit log\n";
open(OUT,">Changes") or die "Can not open 'Changes' for writing\n";
open(IN,"git log --abbrev-commit --pretty |") or die "Problem running git log\n";
while(<IN>){
  # read the change log
  if (/^commit /) {
    chop;
    # for each commit get the version from git
    my $sha = (split(/ /,$_,2))[1];
       $sha =~ s/\.\.\.$//;
    my $ver = `git name-rev --tags $sha 2>/dev/null`;
       chop $ver;
       $ver =~ s/^.*\///;
       $ver =~ s/~.*$//;
       $ver =~ s/\^.*$//;
       if ($ver =~ /.* undefined/) { $ver = "(no version yet)"; }
    print OUT "commit $sha...   PDF::Create $ver\n";
  } else {
    print OUT;
  }
}
close(OUT);
close(IN);

