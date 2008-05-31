# -*- mode: Perl -*-

# PDF::Create::Outline - PDF outlines tree
# Author: Fabien Tassin <fta@sofaraway.org>
# Version: 1.00
# Copyright 1999 Fabien Tassin <fta@sofaraway.org>

# bugs :
# 31.05.2008  1.00  Markus Baertschi
#                   - Changed vesion to go with PDF::Create

package PDF::Create::Outline;

use strict;
use vars qw(@ISA @EXPORT $VERSION $DEBUG);
use Exporter;
use Carp;
use FileHandle;
use Data::Dumper;

@ISA     = qw(Exporter);
@EXPORT  = qw();
$VERSION = 1.00;
$DEBUG   = 0;

sub new {
  my $this = shift;
  my $class = ref($this) || $this;
  my $self = {};
  bless $self, $class;
  $self->{'Kids'} = [];
  $self;
}

sub add {
  my $self = shift;
  my $outline = new PDF::Create::Outline();
  $outline->{'id'}     = shift;
  $outline->{'name'}   = shift;
  $outline->{'Parent'} = $self;
  $outline->{'pdf'}    = $self->{'pdf'};
  my %params = @_;
  $outline->{'Title'}  = $params{'Title'} if defined $params{'Title'};
  $outline->{'Action'} = $params{'Action'} if defined $params{'Action'};
  $outline->{'Status'} = defined $params{'Status'} &&
    ($params{'Status'} eq 'closed' || !$params{'Status'}) ? 0 : 1;
  $outline->{'Dest'}   = $params{'Destination'}
    if defined $params{'Destination'};
  push @{$self->{'Kids'}}, $outline;
  $outline;
}

sub count {
  my $self = shift;

  my $c = scalar @{$self->{'Kids'}};
  return $c unless $c;
  for my $outline (@{$self->{'Kids'}}) {
    my $v = $outline->count;
    $c += $v if $outline->{'Status'};
  }
  $c *= -1 unless $self->{'Status'};
  $c;
}

sub kids {
  my $self = shift;

  my $t = [];
  map { push @$t, $_->{'id'} } @{$self->{'Kids'}};
  $t;
}

sub list {
  my $self = shift;
  my @l;
  for my $e (@{$self->{'Kids'}}) {
    my @t = $e->list;
    push @l, $e;
    push @l, @t if scalar @t;
  }
  @l;
}

sub new_outline {
  my $self = shift;

  $self->{'pdf'}->new_outline('Parent' => $self, @_);
}

1;
