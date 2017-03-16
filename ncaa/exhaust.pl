#!/usr/bin/perl

use strict;
use warnings;

our @round_scores = (2,3,6,9,12,15);  # hoops
#our @round_scores = (10,20,40,80,160,320); # cbssports
our $score_add_seed = undef; #hoops
#our $score_add_seed = 1; # cbssports;

# game sequence
# In each region:
# 1-16
# 8-9
# 5-12
# 4-13
# 6-11
# 3-14
# 7-10
# 2-15
# 1-16-8-9
# 5-12-4-13
# 6-11-3-14
# 7-10-2-15
# 1-16-8-9-5-12-4-13
# 6-11-3-14-7-10-2-15
# regional
#
# then:
# east-west
# midwest-south
# championship

# gameid:
# region - round - game, where the lower game number from the feeding games is used in this round.  game and round are zero based here.
# In that game, the winner of region - (round-1) - game plays the winner of region - (round-1) - ((2^(4-round))-1)
# In Round 0, which has no previous round, game refers to the seed (-1) of the team in that region.

# for final four, gameid is just:
# east-west, midwest-south, championship.
#

my %games = ();

sub gameCombatants {
	my ($region, $round, $game) = @_;

}



exit 0;

