#!/usr/bin/perl -w

use strict;
use PDF::Create;
use Test::More;

my @cases = (
	[undef, 'null'],
	['anything', 'null', 'anything'], # any value

	[undef, 'number'],
	['value', 'number', 'value'],     # any value

	["\n",  'cr'],
	["\n",  'cr', 'abc'],             # TODO: probably should complain that a 2nd, unnecesssary param was given

	['true', 'boolean', 'true'],
	['false', 'boolean', 'false'],
	['false', 'boolean', '0'],
	['true', 'boolean', '42'],        # any other value as the 3rd item
#	['true', 'boolean', undef],       # TODO: give error or eliminate warnings

	['any string', 'verbatim', 'any string'],  # anything
	['x', 'verbatim', 'x'],                    # anything
#	[undef, 'verbatim', undef],  # TODO should give error, now fails with unknown type as the do{} fails
#	[0, 'verbatim', 0],          # TODO should work?, now fails with unknown type as the do{} fails


	['(any string)', 'string', 'any string'],  # anything
	['(x)', 'string', 'x'],                    # anything
	['()', 'string', undef],  # TODO what should happen? eliminate warnings 
	['(0)', 'string', 0],

	
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

