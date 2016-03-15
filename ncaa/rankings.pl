#!/usr/bin/perl

use strict;
use warnings;
use Text::CSV;

my $input_file = shift || die "ERROR: Need to specify input file.\n";

my $csv = Text::CSV->new({binary=>1}) or die "ERROR: Failed creating Text::CSV object\n";

my $fh;
open $fh, "<:encoding(utf8)", $input_file or die "ERROR: opening [$input_file]\n";
my @rows = ();
while(my $row = $csv->getline($fh)) {
	push @rows, $row;
}
$csv->eof or $csv->error_diag();
close($fh);

foreach(@rows) {


}



exit(0);

