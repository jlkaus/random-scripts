#!/usr/bin/perl

use strict;
use warnings;
use utf8;

my $field_tab = shift || die "ERROR: Must specify field filename.\n";

my $ifh;
my $ofh;
open $ifh, "<:encoding(utf8)",$field_tab or die "ERROR: Unable to open [$field_tab] for reading.\n";

my $field_csv = $field_tab;
$field_csv =~ s/\.tab$/\.csv/;
open $ofh, ">:encoding(utf8)", $field_csv or die "ERROR: Unable to open [$field_csv] for writing.\n";

my $cur_region = undef;
my $cur_loc = undef;
my $cur_rank = undef;
while(<$ifh>) {
  chomp;
  if(/^\s*$/) {
    # ignore empty lines
  } elsif(/^Seed.*$/) {
    # ignore header row
  } elsif(/^([^-]+) – (.+)$/) {
    $cur_region = $1;
    $cur_loc = $2;
    print STDERR "Found region [$1] at location [$2]\n";
  } elsif(/^([[:digit:]]+)\*?\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([[:digit:]]+)$/) {
    print $ofh "\"$cur_region\",\"$cur_loc\",\"$1\",\"$2\",\"$6\"\n";
    $cur_rank = $1;
  } elsif(/^([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([[:digit:]]+)$/) {
    print $ofh "\"$cur_region\",\"$cur_loc\",\"$cur_rank\",\"$1\",\"$5\"\n";
  } else {
    die "ERROR: Don't understand line [$_]\n";
  }
}






close $ofh;
close $ifh;

exit(0);

