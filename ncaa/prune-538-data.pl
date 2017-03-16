#!/usr/bin/perl

use strict;
use warnings;

# prune the 538 data after initial playins have occurred, and forecast data updated, etc.
our $gender="mens";
our $team_alive="1";
our $forecast_date="2017-03-15";

while(<>) {
	chomp;
	my @fields = split /,/, $_, 16;
	# fields are:
	# 0 gender
	# 1 forecast_date
	# 2 playin_flag
	# 3 rd1_win
	# 4 rd2_win
	# 5 rd3_win
	# 6 rd4_win
	# 7 rd5_win
	# 8 rd6_win
	# 9 rd7_win
	# 10 team_alive
	# 11 team_id
	# 12 team_name
	# 13 team_rating
	# 14 team_region
	# 15 team_seed

	if($fields[0] eq $gender &&
	   $fields[1] eq $forecast_date &&
	   $fields[10] eq $team_alive) {
	   	$fields[15] =~ s/^([[:digit:]]+)[ab]$/$1/;
		print join(',', @fields[14,15,11,12,13,4,5,6,7,8,9]), "\n";
	}
}
exit 0;

