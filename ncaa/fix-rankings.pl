#!/usr/bin/perl

use strict;
use warnings;

my $source_file = shift || die "ERROR: Must give a source filename.\n";

my $prefix = "";
if($source_file =~ /^(.*)\.csv$/) {
	$prefix = $1;
}

my $ifh;
my $ofh = undef;
open $ifh, "<:encoding(utf8)", $source_file or die "ERROR: Unable to open [$source_file] for reading.\n";

my $inscript = undef;
while(<$ifh>) {
	chomp;
	if(/^\s*$/) {
		# ignore empty lines
	} elsif(/^Reclassifying$/) {
		# ignore these
	} elsif(/^\s*<script .*$/) {
		$inscript = 1;
	} elsif(/^\s*<\/script>\s*$/) {
		$inscript = undef;
	} elsif(!$inscript && /^NCAA Men's Basketball$/) {
		# ignore
	} elsif(!$inscript && /^Through Games .*$/) {
		# ignore
	} elsif(!$inscript && /^Division I(.+)$/) {
		# looks like we found a new table
		print "Found new table: [$1]\n";
		if(defined $ofh) {
			close $ofh;
			$ofh = undef;
		}
		my $tname = $1;
		$tname =~ s/\s+/_/g;
		open $ofh, ">:encoding(utf8)", "$prefix.$tname.csv" or die "ERROR: Unable to open [$prefix.$tname.csv] for writing.\n";
	} elsif(!$inscript && /^"/) {
		# valid line. Add to current table.
		if(defined $ofh) {
			print $ofh "$_\n";
		} else {
			die "ERROR: Found valid row outside of a table?\n";
		} 
	} elsif($inscript) {
		# ignore stuff in scripts
	} else {
		die "ERROR: Don't understand line [$_]\n";
	}
}

if(defined $ofh) {
	close $ofh;
	$ofh = undef;
}

exit(0);

