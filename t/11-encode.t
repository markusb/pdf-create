#!/usr/bin/perl -w

use strict;
use PDF::Create;
use Test::More;

my @cases = (
	[undef, 'null'],
	[undef, 'number'],
	["\n",  'cr'],

	['true', 'boolean', 'true'],
	['false', 'boolean', 'false'],
	['false', 'boolean', '0'],
	['true', 'boolean', '42'], # any other value as the 3rd item
);

plan tests => 1+@cases;

{
	my @warn;
	local $SIG{__WARN__} = sub { push @warn, @_ };
	PDF::Create::encode();
	# TODO eliminat warning from code caused by undef in $type
	like $warn[1], qr/PDF::Create::encode: empty argument, called by/, 'no params';
};

foreach my $c (@cases) {
	my $expected = shift @$c;
	is PDF::Create::encode(@$c),   $expected, join ",", @$c;
}

