#!/usr/bin/perl -w
#
# PDF::Create - Test Script
#
# Copyright 2010-     Markus Baertschi <markus@markus.org>
#
# Please see the CHANGES and Changes file for the detailed change log
#
# Check module versions against PDF::Create version
#

BEGIN { unshift @INC, "lib", "../lib" }
use strict;
use PDF::Create;
use Test::More tests => 5;

my $version = $PDF::Create::VERSION;

ok($version eq $PDF::Create::VERSION,"PDF::Create version is $PDF::Create::VERSION");
ok($version eq $PDF::Create::Page::VERSION,"PDF::Create::Page version is $PDF::Create::Page::VERSION");
ok($version eq $PDF::Create::Outline::VERSION,"PDF::Create::Outline version is $PDF::Create::Outline::VERSION");
ok($version eq $PDF::Image::GIF::VERSION,"PDF::Image::GIF version is $PDF::Image::GIF::VERSION");
ok($version eq $PDF::Image::JPEG::VERSION,"PDF::Image::JPEG version is $PDF::Image::JPEG::VERSION");
