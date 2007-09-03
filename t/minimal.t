# -*- mode: Perl -*-

# Pseudo test file. Usefull to avoid a failure when all other test files
# are skipped.
# There's no real test files because I don't know how such a thing can
# be tested except using a browser or a PDF parser... ideas are welcome.

BEGIN { unshift @INC, "lib", "../lib" }
use strict;
use PDF::Create;

print "1..1\nok 1\n";
