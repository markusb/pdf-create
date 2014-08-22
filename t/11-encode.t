#!/usr/bin/perl -w
use strict;
use PDF::Create;
use Test::More;


# The cases array contains test-cases
# In each triple the first value is the expected return value
# of the encode() method.
# The second and third values are the two parameters
# of the encode() method.
# The third parameter is optional but it can also be a complex
# data structure.
# expected, type, value
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


	# TODO: shouldn't this check if the given value was indeed a number?
	['any string', 'number', 'any string'],  # anything
	['x', 'number', 'x'],                    # anything
	[undef, 'number', undef],  # TODO eliminate warnngs
	[0, 'number', 0],


	['/any string', 'name', 'any string'],  # anything
	['/x', 'name', 'x'],                    # anything
	['/', 'name', undef],  # TODO ???, eliminate warnings
	['/0', 'name', 0],

	['[/anything]', 'array', [
			['name', 'anything'],
		]
	],
	['[/42 abc]', 'array', [
			['name', 42],
			['verbatim', 'abc'],
		]
	],

	# TODO more complex test cases for dictionary
	["<<\n/42 /text\n/abc (qwe)\n>>", 'dictionary', {
			42 => ['name', 'text'],
			abc => ['string', 'qwe'],
		}
	],

	# TODO more complex test cases for object
	["abc 43 obj\n/qwe\nendobj", 'object', [
		'abc', 43, ['name', 'qwe']
		]
	],

	["abc 45 R", 'ref', ['abc', 45]],

	["<<\n/abc 46\n/23 /qwe\n>>\nstream\nsome data\nendstream\n",
	'stream', {
			Data => 'some data',
			abc  => ['number', 46],
			23   => ['name', 'qwe'],
		}
	],
);

plan tests => 2 + @cases;

{
	my @warn;
	local $SIG{__WARN__} = sub { push @warn, @_ };
	PDF::Create::encode();
	# TODO eliminat warning from code caused by undef in $type
	like $warn[1], qr/PDF::Create::encode: empty argument, called by/, 'no params';
};

eval {
	PDF::Create::encode('something');
};
like $@, qr{Error: unknown type 'something'}, 'exception';

my %too_random = map { $_ => 1 } qw(dictionary stream);

foreach my $c (@cases) {
	my ($expected, $type, $value) = @$c;

	SKIP: {
		if ($too_random{$type}) {
			if (defined $ENV{PERL_PERTURB_KEYS} and $ENV{PERL_PERTURB_KEYS} == 2
				and defined $ENV{PERL_HASH_SEED} and $ENV{PERL_HASH_SEED} == 1) {
			} else {
				skip 'PERL_PERTURB_KEYS=2 and PERL_HASH_SEED=1 has to be in order to have predictable Hashes', 1;
			}
		}
		my $name = $type . (defined $value ? ",$value" : '');
		is PDF::Create::encode($type, $value), $expected, $name;
	}
}

