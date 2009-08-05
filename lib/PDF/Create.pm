# -*- mode: Perl -*-
#
# PDF::Create - create PDF files
#
# Author: Fabien Tassin <fta@sofaraway.org>
#
# Copyright 1999-2001 Fabien Tassin <fta@sofaraway.org>
# Copyright 2007      Markus Baertschi <markus@markus.org>
#
# 03.09.2007  0.08  Markus Baertschi <markus@markus.org>
#                   - Fixed error checking on file open
#    04.2008  0.09  Markus Baertschi <markus@markus.org>
#                   - Clarified documentation
# 28.05.2008  0.10  Markus Baertschi <markus@markus.org>
#                   - Additional error checking in encode
#                   - Made DEBUG accessible from outside
#                   - Add more debug statements
#                   - Fixed 'Rotate'
#                   - Added 'number' to encode (required for 'Rotate')
#                   - More Comments and POD Cleanup
#                   - Never released due to cpan versioning limitation
# 31.05.2008  1.0   Markus Baertschi <markus@markus.org>
# 		    - Added sample-cgi.pl
# 		    - Added cgi example to POD

package PDF::Create;

our $VERSION = "1.04";
our $DEBUG   = 0;

use strict;
use Carp qw(confess croak cluck carp);
use FileHandle;
use PDF::Create::Page;
use PDF::Create::Outline;
use PDF::Image::GIF;
use PDF::Image::JPEG;
use vars qw($DEBUG);

our (@ISA, @EXPORT, @EXPORT_OK, @EXPORT_FAIL);
require Exporter;
@ISA     = qw(Exporter);
@EXPORT  = qw();
@EXPORT_OK = qw($DEBUG $VERSION);

# Create a new object
sub new {
  my $this = shift;
  my %params = @_;

  my $class = ref($this) || $this;
  my $self = {};
  bless $self, $class;
  $self->{'data'}    = '';
  $self->{'version'} = $params{'Version'} || "1.2";
  $self->{'trailer'} = {};

  $self->{'pages'} = new PDF::Create::Page();
  $self->{'current_page'} = $self->{'pages'};
  $self->{'pages'}->{'pdf'} = $self; # circular reference
  $self->{'page_count'} = 0;

  $self->{'outline_count'} = 0;

  $self->{'crossreftblstartaddr'} = 0; # cross-reference table start address
  $self->{'generation_number'} = 0;
  $self->{'object_number'} = 0;

  if (defined $params{'fh'}) {
    $self->{'fh'} = $params{'fh'};
  }
  elsif (defined $params{'filename'}) {
    $self->{'filename'} = $params{'filename'};
    my $fh = new FileHandle "> $self->{'filename'}";
    carp "PDF::Create.pm: $self->{'filename'}: $!\n" unless defined $fh;
    binmode $fh;
    $self->{'fh'} = $fh;
  }
  $self->{'catalog'} = {};
  $self->{'catalog'}{'PageMode'} = $params{'PageMode'}
    if defined $params{'PageMode'};

  # Header: add version
  $self->add_version;
  # Info
  $self->{'Author'} =   $params{'Author'}   if defined $params{'Author'};
  $self->{'Creator'} =  $params{'Creator'}  if defined $params{'Creator'};
  $self->{'Title'} =    $params{'Title'}    if defined $params{'Title'};
  $self->{'Subject'} =  $params{'Subject'}  if defined $params{'Subject'};
  $self->{'Keywords'} = $params{'Keywords'} if defined $params{'Keywords'};
  if (defined $params{'CreationDate'}) {
    $self->{'CreationDate'} =
      sprintf "D:%4u%0.2u%0.2u%0.2u%0.2u%0.2u",
	$params{'CreationDate'}->[5] + 1900, $params{'CreationDate'}->[4] + 1,
	$params{'CreationDate'}->[3], $params{'CreationDate'}->[2],
	$params{'CreationDate'}->[1], $params{'CreationDate'}->[0];
  }
  return $self;
}

#
# Close does the work of creating the PDF data from the
# objects collected before.
#
sub close {
  my $self = shift;
  my %params = @_;

  $self->debug("Closing PDF");
  $self->page_stream;
  $self->add_outlines if defined $self->{'outlines'};
  $self->add_catalog;
  $self->add_pages;
  $self->add_info;
  $self->add_crossrefsection;
  $self->add_trailer;
  $self->{'fh'}->close
    if defined $self->{'fh'} && defined $self->{'filename'};
  $self->{'data'};
}

#
# Helper fonction for debugging
# Prints the passed message if debugging is on
#
sub debug {
  return unless $DEBUG;
  my $self = shift;
  my $msg = shift;

  my $s = scalar @_ ? sprintf $msg, @_ : $msg;
  warn "PDF DEBUG: $s\n";
}

#
# Set/Return the PDF version
#
sub version {
  my $self = shift;
  my $v = shift;

  if (defined $v) {
    # TODO: should test version (1.0 to 1.3)
    $self->{'version'} = $v;
  }
  $self->{'version'};
}

# Add some data to the current PDF structure.
sub add {
  my $self = shift;
  my $data = join '', @_;
  $self->{'size'} += length $data;
  if (defined $self->{'fh'}) {
    my $fh = $self->{'fh'};
    print $fh $data;
  }
  else {
    $self->{'data'} .= $data;
  }
}

# Get the current position in the PDF
sub position {
  my $self = shift;

  $self->{'size'};
}

# Reserve the next object number for the given object type.
sub reserve {
  my $self = shift;
  my $name = shift;
  my $type = shift || $name;

  die "Error: an object has already been reserved using this name '$name' "
    if defined $self->{'reservations'}{$name};
  $self->{'object_number'}++;
  $self->{'reservations'}{$name} = [ $self->{'object_number'},
				     $self->{'generation_number'},
				     $type
				   ];
  [ $self->{'object_number'}, $self->{'generation_number'} ];
}

sub add_version {
  my $self = shift;
  $self->debug("adding version");
  $self->add("%PDF-" . $self->{'version'});
  $self->cr;
}

sub add_comment {
  my $self = shift;
  my $comment = shift || '';
  $self->debug("adding comment");
  $self->add("%" . $comment);
  $self->cr;
}

sub encode {
  my $type = shift;
  my $val = shift;

  if ($DEBUG) {if ($val) {warn("encode: $type $val");}
                    else {warn("encode: $type (no val)");}}
  if (! $type) {cluck "PDF::Create::encode: empty argument, called by "; return 1}
  ($type eq 'null' || $type eq 'number') && do {
    1; # do nothing
  } || $type eq 'cr' && do {
    $val = "\n";
  } || $type eq 'boolean' && do {
    $val = $val eq 'true' ? $val : $val eq 'false' ? $val :
    $val eq '0' ? 'false' : 'true';
  } || $type eq 'string' && do {
    $val = "($val)"; # TODO: split it. Quote parentheses.
  } || $type eq 'number' && do {
    $val = "$val";
  } || $type eq 'name' && do {
    $val = "/$val";
  } || $type eq 'array' && do {
    # array, encode contents individually
    my $s = '[';
    for my $v (@$val) {
      $s .= &encode($$v[0], $$v[1]) . " ";
    }
    chop $s; # remove the trailing space
    $val = $s . "]";
  } || $type eq 'dictionary' && do {
    my $s = '<<' . &encode('cr');
    for my $v (keys %$val) {
      $s .= &encode('name', $v) . " ";
      $s .= &encode(${$$val{$v}}[0], ${$$val{$v}}[1]);#  . " ";
      $s .= &encode('cr');
    }
    $val = $s . ">>";
  } || $type eq 'object' && do {
    my $s = &encode('number', $$val[0]) . " " .
      &encode('number', $$val[1]) . " obj";
    $s .= &encode('cr');
    $s .= &encode($$val[2][0], $$val[2][1]);#  . " ";
    $s .= &encode('cr');
    $val = $s . "endobj";
  } || $type eq 'ref' && do {
    my $s = &encode('number', $$val[0]) . " " .
      &encode('number', $$val[1]) . " R";
    $val = $s;
  } || $type eq 'stream' && do {
    my $data = delete $$val{'Data'};
    my $s = '<<' . &encode('cr');
    for my $v (keys %$val) {
      $s .= &encode('name', $v) . " ";
      $s .= &encode(${$$val{$v}}[0], ${$$val{$v}}[1]);#  . " ";
      $s .= &encode('cr');
    }
    $s .= ">>" . &encode('cr') . "stream" . &encode('cr');
    $s .= $data . &encode('cr');
    $val = $s . "endstream" . &encode('cr');
  } || confess "Error: unknown type '$type'";
  # TODO: add type 'text';
  $val;
}

sub add_object {
  my $self = shift;
  my $v = shift;

  my $val = &encode(@$v);
  $self->add($val);
  $self->cr;
  [ $$v[1][0], $$v[1][1] ];
}

sub null {
  my $self = shift;
  [ 'null', 'null' ];
}

sub boolean {
  my $self = shift;
  my $val = shift;
  [ 'boolean', $val ];
}

sub number {
  my $self = shift;
  my $val = shift;
  [ 'number', $val ];
}

sub name {
  my $self = shift;
  my $val = shift;
  [ 'name', $val ];
}

sub string {
  my $self = shift;
  my $val = shift;
  [ 'string', $val ];
}

sub array {
  my $self = shift;
  [ 'array', [ @_ ] ];
}

sub dictionary {
  my $self = shift;
  [ 'dictionary', { @_ } ];
}

sub indirect_obj {
  my $self = shift;
  my ($id, $gen);
  my $name = $_[1];
  my $type = $_[0][1]{'Type'}[1]
    if defined $_[0][1] && ref $_[0][1] eq 'HASH' && defined $_[0][1]{'Type'};
  if (defined $name && defined $self->{'reservations'}{$name}) {
    ($id, $gen) = @{$self->{'reservations'}{$name}};
    delete $self->{'reservations'}{$name};
  }
  elsif (defined $type && defined $self->{'reservations'}{$type}) {
    ($id, $gen) = @{$self->{'reservations'}{$type}};
    delete $self->{'reservations'}{$type};
  }
  else {
    $id = ++$self->{'object_number'};
    $gen = $self->{'generation_number'};
  }
  push @{$self->{'crossrefsubsection'}{$gen}}, [ $id, $self->position, 1 ];
  [ 'object', [ $id, $gen, @_ ] ];
}

sub indirect_ref {
  my $self = shift;
  [ 'ref', [ @_ ] ];
}

sub stream {
  my $self = shift;
  [ 'stream', { @_ } ];
}

sub add_info {
  my $self = shift;

  $self->debug("add_info");
  my %params = @_;
  $params{'Author'}       = $self->{'Author'}   if defined $self->{'Author'};
  $params{'Creator'}      = $self->{'Creator'}  if defined $self->{'Creator'};
  $params{'Title'}        = $self->{'Title'}    if defined $self->{'Title'};
  $params{'Subject'}      = $self->{'Subject'}  if defined $self->{'Subject'};
  $params{'Keywords'}     = $self->{'Keywords'} if defined $self->{'Keywords'};
  $params{'CreationDate'} = $self->{'CreationDate'}
    if defined $self->{'CreationDate'};

  $self->{'info'} = $self->reserve('Info');
  my $content = { 'Producer' => $self->string("PDF::Create version $VERSION"),
		  'Type'     => $self->name('Info') };
  $$content{'Author'} = $self->string($params{'Author'})
    if defined $params{'Author'};
  $$content{'Creator'} = $self->string($params{'Creator'})
    if defined $params{'Creator'};
  $$content{'Title'} = $self->string($params{'Title'})
    if defined $params{'Title'};
  $$content{'Subject'} = $self->string($params{'Subject'})
    if defined $params{'Subject'};
  $$content{'Keywords'} = $self->string($params{'Keywords'})
    if defined $params{'Keywords'};
  $$content{'CreationDate'} = $self->string($params{'CreationDate'})
    if defined $params{'CreationDate'};
  $self->add_object(
    $self->indirect_obj(
      $self->dictionary(%$content)), 'Info');
  $self->cr;
}

# Catalog specification.
sub add_catalog {
  my $self = shift;

  $self->debug("add_catalog");
  my %params = %{$self->{'catalog'}};
  # Type (mandatory)
  $self->{'catalog'} = $self->reserve('Catalog');
  my $content = { 'Type' => $self->name('Catalog') };
  # Pages (mandatory) [indirected reference]
  my $pages = $self->reserve('Pages');
  $$content{'Pages'} = $self->indirect_ref(@$pages);
  $self->{'pages'}{'id'} = $$content{'Pages'}[1];
  # Outlines [indirected reference]
  $$content{'Outlines'} = $self->indirect_ref(@{$self->{'outlines'}->{'id'}})
    if defined $self->{'outlines'};
  # PageMode
  $$content{'PageMode'} = $self->name($params{'PageMode'})
    if defined $params{'PageMode'};

  $self->add_object(
    $self->indirect_obj(
      $self->dictionary(%$content)));
  $self->cr;
}

sub add_outlines {
  my $self = shift;

  $self->debug("add_outlines");
  my %params = @_;
  my $outlines = $self->reserve("Outlines");

  my ($First, $Last);
  my @list = $self->{'outlines'}->list;
  my $i = -1;
  for my $outline (@list) {
    $i++;
    my $name = $outline->{'name'};
    $First = $outline->{'id'} unless defined $First;
    $Last =  $outline->{'id'};
    my $content = { 'Title' => $self->string($outline->{'Title'}) };
    if (defined $outline->{'Kids'} && scalar @{$outline->{'Kids'}}) {
      my $t = $outline->{'Kids'};
      $$content{'First'} = $self->indirect_ref(@{$$t[0]->{'id'}});
      $$content{'Last'} = $self->indirect_ref(@{$$t[$#$t]->{'id'}});
    }
    my $brothers = $outline->{'Parent'}->{'Kids'};
    my $j = -1;
    for my $brother (@$brothers) {
      $j++;
      last if $brother == $outline;
    }
    $$content{'Next'} = $self->indirect_ref(@{$$brothers[$j + 1]->{'id'}})
      if $j < $#$brothers;
    $$content{'Prev'} = $self->indirect_ref(@{$$brothers[$j - 1]->{'id'}})
      if $j;
    $outline->{'Parent'}->{'id'} = $outlines
      unless defined $outline->{'Parent'}->{'id'};
    $$content{'Parent'} = $self->indirect_ref(@{$outline->{'Parent'}->{'id'}});
    $$content{'Dest'} =
      $self->array($self->indirect_ref(@{$outline->{'Dest'}->{'id'}}),
		   $self->name('Fit'), $self->null, $self->null, $self->null);
    my $count = $outline->count;
    $$content{'Count'} = $self->number($count) if $count;
    my $t = $self->add_object(
      $self->indirect_obj(
        $self->dictionary(%$content), $name));
    $self->cr;
  }

  # Type (required)
  my $content = { 'Type' => $self->name('Outlines') };
  # Count
  my $count = $self->{'outlines'}->count;
  $$content{'Count'} = $self->number($count) if $count;
  $$content{'First'} = $self->indirect_ref(@$First);
  $$content{'Last'}  = $self->indirect_ref(@$Last);
  $self->add_object(
    $self->indirect_obj(
      $self->dictionary(%$content)));
  $self->cr;
}

sub new_outline {
  my $self = shift;

  my %params = @_;
  unless (defined $self->{'outlines'}) {
    $self->{'outlines'} = new PDF::Create::Outline();
    $self->{'outlines'}->{'pdf'} = $self; # circular reference
    $self->{'outlines'}->{'Status'} = 'opened';
  }
  my $parent = $params{'Parent'} || $self->{'outlines'};
  my $name   = "Outline " . ++$self->{'outline_count'};
  $params{'Destination'} = $self->{'current_page'}
    unless defined $params{'Destination'};
  my $outline = $parent->add($self->reserve($name, "Outline"), $name, %params);
  $outline;
}

sub get_page_size {
  my $self = shift;
  my $name = lc(shift);
  
  my %pagesizes = (
     'A0'         => [ 0, 0, 2380, 3368 ],
     'A1'         => [ 0, 0, 1684, 2380 ],
     'A2'         => [ 0, 0, 1190, 1684 ],
     'A3'         => [ 0, 0, 842,  1190 ],
     'A4'         => [ 0, 0, 595,  842  ],
     'A4L'        => [ 0, 0, 842,  595  ],
     'A5'         => [ 0, 0, 421,  595  ],
     'A6'         => [ 0, 0, 297,  421  ],
     'LETTER'     => [ 0, 0, 612,  792  ],
     'BROADSHEET' => [ 0, 0, 1296, 1584 ],
     'LEDGER'     => [ 0, 0, 1224, 792  ],
     'TABLOID'    => [ 0, 0, 792,  1224 ],
     'LEGAL'      => [ 0, 0, 612,  1008 ],
     'EXECUTIVE'  => [ 0, 0, 522,  756  ],
     '36X36'      => [ 0, 0, 2592, 2592 ],
  );
  
  if (!$pagesizes{uc($name)}) {
      $name = "A4";
  }
  
  $pagesizes{uc($name)};
}  

sub new_page {
  my $self = shift;

  my %params = @_;
  my $parent = $params{'Parent'} || $self->{'pages'};
  my $name = "Page " . ++$self->{'page_count'};
  my $page = $parent->add($self->reserve($name, "Page"), $name);
  $page->{'resources'} = $params{'Resources'} if defined $params{'Resources'};
  $page->{'mediabox'}  = $params{'MediaBox'}  if defined $params{'MediaBox'};
  $page->{'cropbox'}   = $params{'CropBox'}   if defined $params{'CropBox'};
  $page->{'artbox'}    = $params{'ArtBox'}    if defined $params{'ArtBox'};
  $page->{'trimbox'}   = $params{'TrimBox'}   if defined $params{'TrimBox'};
  $page->{'bleedbox'}  = $params{'BleedBox'}  if defined $params{'BleedBox'};
  $page->{'rotate'}    = $params{'Rotate'}    if defined $params{'Rotate'};

  $self->{'current_page'} = $page;

  $page;
}

sub add_pages {
  my $self = shift;

  $self->debug("add_pages");
  # $self->page_stream;
  my %params = @_;
  # Type (required)
  my $content = { 'Type' => $self->name('Pages') };
  # Kids (required)
  my $t = $self->{'pages'}->kids;
  die "Error: document MUST contains at least one page. Abort."
    unless scalar @$t;
  my $kids = [];
  map { push @$kids, $self->indirect_ref(@$_) } @$t;
  $$content{'Kids'} = $self->array(@$kids);
  $$content{'Count'} = $self->number($self->{'pages'}->count);
  $self->add_object(
    $self->indirect_obj(
      $self->dictionary(%$content)));
  $self->cr;

  for my $font (sort keys %{$self->{'fonts'}}) {
    $self->debug("add_pages: font: $font");
    $self->{'fontobj'}{$font} = $self->reserve('Font');
    $self->add_object(
      $self->indirect_obj(
        $self->dictionary(%{$self->{'fonts'}{$font}}), 'Font'));
    $self->cr;
  }

  for my $xobject (sort keys %{$self->{'xobjects'}}) {
    $self->debug("add_pages: object: $xobject");
    $self->{'xobj'}{$xobject} = $self->reserve('XObject');
    $self->add_object(
      $self->indirect_obj(
        $self->stream(%{$self->{'xobjects'}{$xobject}}), 'XObject'));
    $self->cr;

    if (defined $self->{'reservations'}{"ImageColorSpace$xobject"}) {
      $self->add_object(
        $self->indirect_obj(
          $self->stream(%{$self->{'xobjects_colorspace'}{$xobject}}), "ImageColorSpace$xobject"));
      $self->cr;
    }  
  }

  for my $page ($self->{'pages'}->list) {
    my $name = $page->{'name'};
    $self->debug("add_pages: page: $name");
    my $type = 'Page' .
      (defined $page->{'Kids'} && scalar @{$page->{'Kids'}} ? 's' : '');
    # Type (required)
    my $content = { 'Type' => $self->name($type) };
    # Resources (required, may be inherited). See page 195.
    my $resources = {};
    for my $k (keys %{$page->{'resources'}}) {
      my $v = $page->{'resources'}{$k};
      ($k eq 'ProcSet') && do {
	my $l = [];
	if (ref($v) eq 'ARRAY') {
	  map { push @$l, $self->name($_) } @$v;
	}
	else {
	  push @$l, $self->name($v);
	}
	$$resources{'ProcSet'} = $self->array(@$l);
      } ||
      ($k eq 'fonts') && do {
	my $l = {};
	map {
	  $$l{"F$_"} = $self->indirect_ref(@{$self->{'fontobj'}{$_}});
	} keys %{$page->{'resources'}{'fonts'}};
	$$resources{'Font'} = $self->dictionary(%$l);
      } ||
      ($k eq 'xobjects') && do {
	my $l = {};
	map {
	  $$l{"Image$_"} = $self->indirect_ref(@{$self->{'xobj'}{$_}});
	} keys %{$page->{'resources'}{'xobjects'}};
	$$resources{'XObject'} = $self->dictionary(%$l);
      };
    }
    if ( defined ( $$resources{'XObject'} ) ) {
      my $r = $self->add_object(
				$self->indirect_obj(
						    $self->dictionary(%$resources)));
      $self->cr;
      $$content{'Resources'} = [ 'ref', [ $$r[0], $$r[1] ] ];
    } else {
      $$content{'Resources'} = $self->dictionary(%$resources)
	if scalar keys %$resources;
    }
    for my $K ('MediaBox', 'CropBox', 'ArtBox', 'TrimBox', 'BleedBox') {
      my $k = lc $K;
      if (defined $page->{$k}) {
	my $l = [];
	map { push @$l, $self->number($_) } @{$page->{$k}};
	$$content{$K} = $self->array(@$l);
      }
    }
    $$content{'Rotate'} = $self->number($page->{'rotate'}) if defined $page->{'rotate'};
    if ($type eq 'Page') {
      $$content{'Parent'} = $self->indirect_ref(@{$page->{'Parent'}{'id'}});
      # Content
      if (defined $page->{'contents'}) {
	my $contents = [];
	map {
	  push @$contents, $self->indirect_ref(@$_);
	} @{$page->{'contents'}};
	$$content{'Contents'} = $self->array(@$contents);
      }
    }
    else {
      my $kids = [];
      map { push @$kids, $self->indirect_ref(@$_) } @{$page->kids};
      $$content{'Kids'} = $self->array(@$kids);
      $$content{'Parent'} = $self->indirect_ref(@{$page->{'Parent'}{'id'}})
	if defined $page->{'Parent'};
      $$content{'Count'} = $self->number($page->count);
    }
    $self->add_object(
      $self->indirect_obj(
        $self->dictionary(%$content), $name));
    $self->cr;
  }
}

sub add_crossrefsection {
  my $self = shift;

  $self->debug("adding cross reference section");
  # <cross-reference section> ::=
  #   xref
  #   <cross-reference subsection>+
  $self->{'crossrefstartpoint'} = $self->position;
  $self->add('xref');
  $self->cr;
  die "Fatal error: should contains at least one cross reference subsection."
    unless defined $self->{'crossrefsubsection'};
  for my $subsection (sort keys %{$self->{'crossrefsubsection'}}) {
    $self->add_crossrefsubsection($subsection);
  }
}

sub add_crossrefsubsection {
  my $self = shift;
  my $subsection = shift;

  $self->debug("adding cross reference subsection");
  # <cross-reference subsection> ::=
  #   <object number of first entry in subsection>
  #   <number of entries in subsection>
  #   <cross-reference entry>+
  #
  # <cross-reference entry> ::= <in-use entry> | <free entry>
  #
  # <in-use entry> ::= <byte offset> <generation number> n <end-of-line>
  #
  # <end-of-line> ::= <space> <carriage return>
  #   | <space> <linefeed>
  #   | <carriage return> <linefeed>
  #
  # <free entry> ::=
  #   <object number of next free object>
  #   <generation number> f <end-of-line>

  $self->add(0, ' ',
    1 + scalar @{$self->{'crossrefsubsection'}{$subsection}});
  $self->cr;
  $self->add(sprintf "%010d %05d %s ", 0, 65535, 'f');
  $self->cr;
  for my $entry (sort { $$a[0] <=> $$b[0] }
		 @{$self->{'crossrefsubsection'}{$subsection}}) {
    $self->add(sprintf "%010d %05d %s ", $$entry[1], $subsection,
	      $$entry[2] ? 'n' : 'f');
    # printf "%010d %010x %05d n\n", $$entry[1], $$entry[1], $subsection;
    $self->cr;
  }

}

sub add_trailer {
  my $self = shift;
  $self->debug("adding trailer");

  # <trailer> ::= trailer
  #   <<
  #   <trailer key value pair>+
  #   >>
  #   startxref
  #   <cross-reference table start address>
  #   %%EOF

  my @keys = (
     'Size',    # integer (required)
     'Prev',    # integer (req only if more than one cross-ref section)
     'Root',    # dictionary (required)
     'Info',    # dictionary (optional)
     'ID',      # array (optional) (PDF 1.1)
     'Encrypt'  # dictionary (req if encrypted) (PDF 1.1)
  );

  # TODO: should check for required fields
  $self->add('trailer');
  $self->cr;
  $self->add('<<');
  $self->cr;
  $self->{'trailer'}{'Size'} = 1;
  map {
    $self->{'trailer'}{'Size'} += scalar @{$self->{'crossrefsubsection'}{$_}}
  } keys %{$self->{'crossrefsubsection'}};
  $self->{'trailer'}{'Root'} =
    &encode(@{$self->indirect_ref(@{$self->{'catalog'}})});
  $self->{'trailer'}{'Info'} =
    &encode(@{$self->indirect_ref(@{$self->{'info'}})})
      if defined $self->{'info'};
  for my $k (@keys) {
    next unless defined $self->{'trailer'}{$k};
    $self->add("/$k ", ref $self->{'trailer'}{$k} eq 'ARRAY' ?
	       join(' ', @{$self->{'trailer'}{$k}}) : $self->{'trailer'}{$k});
    $self->cr;
  }
  $self->add('>>');
  $self->cr;
  $self->add('startxref');
  $self->cr;
  $self->add($self->{'crossrefstartpoint'});
  $self->cr;
  $self->add('%%EOF');
  $self->cr;
}

sub cr {
  my $self = shift;
  # $self->debug("adding CR");
  $self->add(&encode('cr'));
}

sub page_stream {
  my $self = shift;
  my $page = shift;
#  $self->debug("page_stream: page=$page");

  if (defined $self->{'reservations'}{'stream_length'}) {
    ## If it is the same page, use the same stream.
    $self->cr, return if defined $page && defined $self->{'stream_page'} &&
      $page == $self->{'current_page'} && $self->{'stream_page'} == $page;
    # Remember the position
    my $len = $self->position - $self->{'stream_pos'} + 1;
    # Close the stream and the object
    $self->cr;
    $self->add('endstream');
    $self->cr;
    $self->add('endobj');
    $self->cr;
    $self->cr;
    # Add the length
    $self->add_object(
      $self->indirect_obj(
        $self->number($len), 'stream_length'));
    $self->cr;
  }
  # open a new stream if needed
  if (defined $page) {
    # get an object id for the stream
    my $obj = $self->reserve('stream');
    # release it
    delete $self->{'reservations'}{'stream'};
    # get another one for the length of this stream
    my $stream_length = $self->reserve('stream_length');
    push @$stream_length, 'R';
    push @{$page->{'contents'}}, $obj;
    # write the beginning of the object
    push @{$self->{'crossrefsubsection'}{$$obj[1]}},
      [ $$obj[0], $self->position, 1 ];
    $self->add("$$obj[0] $$obj[1] obj");
    $self->cr;
    $self->add('<<');
    $self->cr;
    $self->add('/Length ', join (' ', @$stream_length));
    $self->cr;
    $self->add('>>');
    $self->cr;
    $self->add('stream');
    $self->cr;
    $self->{'stream_pos'} = $self->position;
    $self->{'stream_page'} = $page; # $self->{'current_page'};
  }
}

sub font {
  my $self = shift;

  my %params = @_;
  my $num = 1 + scalar keys %{$self->{'fonts'}};
  $self->{'fonts'}{$num} = {
     'Subtype'  => $self->name($params{'Subtype'}  || 'Type1'),
     'Encoding' => $self->name($params{'Encoding'} || 'WinAnsiEncoding'),
     'BaseFont' => $self->name($params{'BaseFont'} || 'Helvetica'),
     'Name'     => $self->name("F$num"),
     'Type'     => $self->name("Font"),
  };
  $num;
}


sub image {
  my $self = shift;
  my $filename = shift;

  my $num = 1 + scalar keys %{$self->{'xobjects'}};
  my $image;

  my $colorspace;
  
  my @a;
  my $s;

  if ($filename=~/\.gif$/i) {
      $self->{'images'}{$num} = PDF::Image::GIF->new();
  } elsif ($filename=~/\.jpg$/i || $filename=~/\.jpeg$/i) {
      $self->{'images'}{$num} = PDF::Image::JPEG->new();
  }

  $image = $self->{'images'}{$num};
  if (!$image->Open($filename)) {
      print $image->{error} . "\n";
      return 0;
  }
  
  $self->{'xobjects'}{$num} = {
     'Subtype'  => $self->name('Image'),
     'Name'     => $self->name("Image$num"),
     'Type'     => $self->name('XObject'),
     'Width'    => $self->number($image->{width}),
     'Height'   => $self->number($image->{height}),
     'BitsPerComponent'   => $self->number($image->{bpc}),
     'Data'     => $image->ReadData(),
     'Length'   => $self->number($image->{imagesize}),
  };

  #indexed colorspace ?
  if ($image->{colorspacesize}) {
      $colorspace = $self->reserve("ImageColorSpace$num");

      $self->{'xobjects_colorspace'}{$num} = {
         'Data'     => $image->{colorspacedata},
         'Length'   => $self->number($image->{colorspacesize}),
      };  

      $self->{'xobjects'}{$num}->{'ColorSpace'} = $self->array($self->name('Indexed'), $self->name($image->{colorspace}), $self->number(255), $self->indirect_ref(@$colorspace));
  } else {
      $self->{'xobjects'}{$num}->{'ColorSpace'} = $self->array($self->name($image->{colorspace}));
  }

  #set Filter
  $#a = -1;
  foreach $s (@{$image->{filter}}) {
      push @a, $self->name($s);
  }    
  if ($#a >= 0) {
      $self->{'xobjects'}{$num}->{'Filter'} = $self->array(@a);
  }    

  #set additional DecodeParms
  $#a = -1;
  foreach $s (keys %{$image->{decodeparms}}) {
      push @a, $s;
      push @a, $self->number($image->{decodeparms}{$s});
  }    
  $self->{'xobjects'}{$num}->{'DecodeParms'} = $self->array($self->dictionary(@a));
  
  #transparent ?
  if ($image->{transparent}) {
      $self->{'xobjects'}{$num}->{'Mask'} = $self->array($self->number($image->{mask}), $self->number($image->{mask}));
  }

  { 'num'=>$num, 'width'=>$image->{width}, 'height'=>$image->{height} };
}


sub uses_font {
  my $self = shift;
  my $page = shift;
  my $font = shift;

  $page->{'resources'}{'fonts'}{$font} = 1;
  $page->{'resources'}{'ProcSet'} = [ 'PDF', 'Text' ];
  $self->{'fontobj'}{$font} = 1;
}

sub uses_xobject {
  my $self = shift;
  my $page = shift;
  my $xobject = shift;

  $page->{'resources'}{'xobjects'}{$xobject} = 1;
  $page->{'resources'}{'ProcSet'} = [ 'PDF', 'Text' ];
  $self->{'xobj'}{$xobject} = 1;
}

sub get_data {
  shift->{'data'};
}

1;

=head1 NAME

PDF::Create - create PDF files

=head1 SYNOPSIS

  use PDF::Create;

  my $pdf = new PDF::Create('filename'     => 'mypdf.pdf',
			    'Version'      => 1.2,
			    'PageMode'     => 'UseOutlines',
			    'Author'       => 'John Doe',
			    'Title'        => 'My Title',
			    'CreationDate' => [ localtime ],
			   );
  # add a A4 sized page
  my $root = $pdf->new_page('MediaBox' => $pdf->get_page_size('A4'));

  # Add a page which inherits its attributes from $root
  my $page = $root->new_page;

  # Prepare 2 fonts
  my $f1 = $pdf->font('Subtype'  => 'Type1',
   		      'Encoding' => 'WinAnsiEncoding',
 		      'BaseFont' => 'Helvetica');
  my $f2 = $pdf->font('Subtype'  => 'Type1',
 		      'Encoding' => 'WinAnsiEncoding',
 		      'BaseFont' => 'Helvetica-Bold');

  # Prepare a Table of Content
  my $toc = $pdf->new_outline('Title' => 'Document',
                              'Destination' => $page);
  $toc->new_outline('Title' => 'Section 1');
  my $s2 = $toc->new_outline('Title' => 'Section 2',
                             'Status' => 'closed');
  $s2->new_outline('Title' => 'Subsection 1');

  $page->stringc($f2, 40, 306, 426, "PDF::Create");
  $page->stringc($f1, 20, 306, 396, "version $PDF::Create::VERSION");

  # Add another page
  my $page2 = $root->new_page;
  $page2->line(0, 0, 612, 792);
  $page2->line(0, 792, 612, 0);

  $toc->new_outline('Title' => 'Section 3');
  $pdf->new_outline('Title' => 'Summary');

  # Add something to the first page
  $page->stringc($f1, 20, 306, 300, 'by John Doe <john.doe@example.com>');

  # Add the missing PDF objects and a the footer then close the file
  $pdf->close;

=head1 DESCRIPTION

PDF::Create allows you to create PDF documents using a number of
primitives. The result is as a PDF file or stream.

PDF stands for Portable Document Format.

Documents can have several pages, a table of content, an information
section and many other PDF elements.

=head1 Methods

=over 5

=item * new

Create a new pdf structure for your pdf.

Example:

  my $pdf = new PDF::Create('filename'     => 'mypdf.pdf',
                            'Version'      => 1.2,
                            'PageMode'     => 'UseOutlines',
                            'Author'       => 'John Doe',
                            'Title'        => 'My title',
			    'CreationDate' => [ localtime ],
                           );

=over 10

=item filename:

destination file that will contain the resulting
PDF or an already opened filehandle or '-' for stdout.

=item Version: 

can be 1.0 to 1.3 (default: 1.2)

=item PageMode: 

how the document should appear when opened. 

Allowed values are:

- UseNone: Open document with neither outline nor thumbnails visible. This is the default value.

- UseOutlines: Open document with outline visible.

- UseThumbs: Open document with thumbnails visible.

- FullScreen: Open document in full-screen mode. In full-screen mode, 
there is no menu bar, window controls, nor any other window present.

=item Author: 

the name of the person who created this document

=item Creator: 

If the document was converted into a PDF document
  from another form, this is the name of the application that
  created the original document.

- Title: the title of the document

- Subject: the subject of the document

- Keywords: keywords associated with the document

- CreationDate: the date the document was created. This is passed
  as an anonymous array in the same format as localtime returns.
  (ie. a struct tm).

=back

If you are writing a CGI and send your PDF on the fly to a browser you
can follow this CGI Example:

  use CGI; use PDF::Create;
  print CGI::header( -type => 'application/x-pdf', -attachment => 'sample.pdf' );
  my $pdf = new PDF::Create('filename'     => '-', # Stdout
                            'Author'       => 'John Doe',
                            'Title'        => 'My title',
			    'CreationDate' => [ localtime ],
                           );


The created object is returned.

=item * close

Most of the real work building the PDF is performed in the close method.
It can there fore not be omitted, like a file close.

=item * get_data

If you didn't ask the $pdf object to write its output to a file, you
can pick up the pdf code by calling this method. It returns a big string.
You need to call C<close> first, mind.

=item * add_comment [string]

Add a comment to the document.

=item * new_outline [parameters]

Add an outline to the document using the given parameters.
Return the newly created outline.

Parameters can be:

- Title: the title of the outline. Mandatory.

- Destination: the destination of this outline. In this version, it is
only possible to give a page as destination. The default destination is
the current page.

- Parent: the parent of this outline in the outlines tree. This is an
outline object.

Example:

  my $outline = $pdf->new_outline('Title' => 'Item 1',
                                  'Destination' => $page);
  $outline->new_outline('Title' => 'Item 1.1');
  $pdf->new_outline('Title' => 'Item 1.2',
                    'Parent' => $outline);
  $pdf->new_outline('Title' => 'Item 2');


=item * new_page

Add a page to the document using the given parameters.
Return the newly created page.

Parameters can be:

- Parent: the parent of this page in the pages tree. This is a
page object.

- Resources: Resources required by this page.

- MediaBox: Rectangle specifying the natural size of the page,
for example the dimensions of an A4 sheet of paper. The coordinates
are measured in default user space units. It must be the reference
of a 4 values array. You can use C<get_page_size> to get the size of
standard paper sizes.
  C<get_page_size> knows about A0-A6, A4L (landscape), Letter, Legal,
Broadsheet, Ledger, Tabloid, Executive and 36x36.

- CropBox: Rectangle specifying the default clipping region for
the page when displayed or printed. The default is the value of
the MediaBox.

- ArtBox: Rectangle specifying an area of the page to be used when
placing PDF content into another application. The default is the value
of the CropBox. [PDF 1.3]

- TrimBox: Rectangle specifying the intended finished size
of the page (for example, the dimensions of an A4 sheet of paper).
In some cases, the MediaBox will be a larger rectangle, which includes
printing instructions, cut marks, or other content. The default is
the value of the CropBox. [PDF 1.3].

- BleedBox: Rectangle specifying the region to which all page
content should be clipped if the page is being output in a production
environment. In such environments, a bleed area is desired, to
accommodate physical limitations of cutting, folding, and trimming
equipment. The actual printed page may include printer's marks that
fall outside the bleed box. The default is the value of the CropBox.
[PDF 1.3]

- Rotate: Specifies the number of degrees the page should be rotated
clockwise when it is displayed or printed. This value must be zero
(the default) or a multiple of 90. The entire page, including contents
is rotated.

=item * get_page_size

Returns the size of standard paper sizes to use for MediaBox-parameter
of C<new_page>. C<get_page_size> has one required parameter to 
specify the paper name. Possible values are a0-a6, letter, broadsheet,
ledger, tabloid, legal, executive and 36x36. Default is a4.

=item * font

Prepare a font using the given arguments. This font will be added
to the document only if it is used at least once before the close method
is called.

Parameters can be:

- Subtype: Type of font. PDF defines some types of fonts. It must be
one of the predefined type Type1, Type3, TrueType or Type0.

In this version, only Type1 is supported. This is the default value.

- Encoding: Specifies the encoding from which the new encoding differs.
It must be one of the predefined encodings MacRomanEncoding,
MacExpertEncoding or WinAnsiEncoding.

In this version, only WinAnsiEncoding is supported. This is the default
value.

- BaseFont: The PostScript name of the font. It can be one of the following
base fonts: Courier, Courier-Bold, Courier-BoldOblique, Courier-Oblique,
Helvetica, Helvetica-Bold, Helvetica-BoldOblique, Helvetica-Oblique,
Times-Roman, Times-Bold, Times-Italic or Times-BoldItalic.

The Symbol or ZapfDingbats fonts are not supported in this version.

The default font is Helvetica.

=item * image filename

Prepare an XObject (image) using the given arguments. This image will be added
to the document if it is referenced at least once before the close method
is called. In this version GIF, interlaced GIF and JPEG is supported. 
Usage of interlaced GIFs are slower because they are decompressed, modified 
and compressed again.
The gif support is limited to images with a lwz min code size of 8. Small
images with few colors can have a smaller min code size. 

Parameters: 

- filename: file name of image (required).

=back

=head2 Page methods

This section describes the methods that can be used by a PDF::Create::Page
object.

In its current form, this class is divided into two main parts, one for
drawing (using PostScript like paths) and one for writing.

Some methods are not described here because they must not be called
directly (e.g. C<new> and C<add>).

=over 5

=item * new_page params

Add a sub-page to the current page.

See C<PDF::Create::new_page>

=item * string font size x y text

Add text to the current page using the font object at the given size and
position. The point (x, y) is the bottom left corner of the rectangle
containing the text.

Example :

    my $f1 = $pdf->font('Subtype'  => 'Type1',
 	   	        'Encoding' => 'WinAnsiEncoding',
 		        'BaseFont' => 'Helvetica');
    $page->string($f1, 20, 306, 396, "some text");

=item * stringl font size x y text

Same as C<string>.

=item * stringr font size x y text

Same as C<string> but right aligned.

=item * stringc font size x y text

Same as C<string> but centered.

=item * printnl text font size x y

Similar to C<string> but parses the string for newline and prints each part
on a separate line. Lines spacing is the same as the font-size. Returns the
number of lines.

Note the different parameter sequence. The first call should specify all
parameters, font is the absolute minimum, a warning will be given for the
missing y position and 800 will be assumed. All subsequent invocations can
omit all but the string parameters.

=item * string_width font text

Return the size of the text using the given font in default user space units.
This does not contain the size of the font yet.

=item * line x1 y1 x2 y2

Draw a line between (x1, y1) and (x2, y2).

=item * set_width w

Set the width of subsequent lines to w points.

=item * setrgbcolor r g b

Set the color of the subsequent drawing operations. R,G and B is a value
between 0.0 and 1.0.

=back

=head2 Low level drawing methods

=over 5

=item * moveto x y

Moves the current point to (x, y), omitting any connecting line segment.

=item * lineto x y

Appends a straight line segment from the current point to (x, y).
The current point is (x, y).

=item * curveto x1 y1 x2 y2 x3 y3

Appends a Bezier curve to the path. The curve extends from the current
point to (x3 ,y3) using (x1 ,y1) and (x2 ,y2) as the Bezier control
points. The new current point is (x3 ,y3).

=item * rectangle x y w h

Adds a rectangle to the current path.

=item * closepath

Closes the current subpath by appending a straight line segment
from the current point to the starting point of the subpath.

=item * newpath

Ends the path without filling or stroking it.

=item * stroke

Strokes the path.

A typical usage is 

  $page->newpath;
  $page->setrgbcolorstroke 0.1 0.3 0.8;
  $page->moveto 100 100;
  $page->lineto 200 100;
  $page->stroke;

=item * closestroke

Closes and strokes the path.

=item * fill

Fills the path using the non-zero winding number rule.

=item * fill2

Fills the path using the even-odd rule

=item * image image_id xpos ypos xalign yalign xscale yscale rotate xskew yskew

Inserts an image.

Parameters can be:

- image: Image id returned by PDF::image (required).

- xpos, ypos: Position of image (required).

- xalign, yalign: Alignment of image. 0 is left/bottom, 1 is centered and 2 is right, top.

- xscale, yscale: Scaling of image. 1.0 is original size.

- rotate: Rotation of image. 0 is no rotation, 2*pi is 360° rotation.

- xskew, yskew: Skew of image.

=back

=head1 SEE ALSO

L<PDF::Create::Page>, L<http://www.adobe.com/devnet/pdf/pdf_reference.html>
L<http://github.com/markusb/pdf-create>

=head1 AUTHORS

Fabien Tassin (fta@sofaraway.org)

GIF and JPEG-support: Michael Gross (info@mdgrosse.net)

Maintenance since 2007: Markus Baertschi (markus@markus.org)

=head1 COPYRIGHT

Copyright 1999-2001, Fabien Tassin. All rights reserved.
It may be used and modified freely, but I do request that
this copyright notice remain attached to the file. You may
modify this module as you wish, but if you redistribute a
modified version, please attach a note listing the modifications
you have made.

Copyright 2007-, Markus Baertschi

=cut
