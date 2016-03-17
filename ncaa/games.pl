#!/usr/bin/perl

use strict;
use warnings;
use Text::CSV;

my $input_dur = shift || die "ERROR: Need to specify input directory.\n";

my $field=undef;

my @field_files = glob("$input_dur/field-????*.csv");

foreach(@field_files) {
  my $fn=$_;
  my $csv=Text::CSV->new({binary=>1}) or die "ERROR: Failed creating Text::CSV object\n";
  my $fh;
  open $fh, "<:encoding(utf8)", $fn or die "ERROR: opening [$fn]\n";
  $csv->column_names("region","location","seed","school","rank");
  $field = $csv->getline_hr_all($fh);
  close($fh);
}

my %regions=();
my %region_top_seed=();
foreach(@{$field}) {
  my $t = $_->{school};
  my $seed=$_->{seed};
  my $rank=$_->{rank};
  my $region=$_->{region};

  $region =~ s/ Regional$//;

  $regions{$region} = [] if !defined $regions{$region};
  $regions{$region}->[$seed] = [] if !defined $regions{$region}->[$seed];
  push @{$regions{$region}->[$seed]}, $t;
#print "Adding $region $seed ($t) to regions\n";

  $region_top_seed{$region} = 100 if !defined $region_top_seed{$region};
  $region_top_seed{$region} = $rank if $rank < $region_top_seed{$region};
}

my @region_best = sort {$region_top_seed{$a} <=>  $region_top_seed{$b}} keys %region_top_seed;

my $rounds = [[[[1,16],[8,9]],[[5,12],[4,13]]],[[[6,11],[3,14]],[[7,10],[2,15]]]];
my $finals = [[$region_best[0],$region_best[3]],[$region_best[1],$region_best[2]]];
my @game_data = ();

my $winner = play_final_game($finals, $rounds, \%regions,0);

print "Winner selected is [$winner]\n";
print "\n";

my $xr = 1;
while(my $gr= pop @game_data) {
  print "Round $xr data\n";
  my $yr = 0;
  my $sr = scalar @{$gr} / 2;
  foreach(@{$gr}) {
    print "[$_]\n";
    ++$yr;
    if($yr == $sr) {
      print "\n";
    }
  }
  print "\n\n";
  ++$xr;
}


exit(0);



sub play_final_game {
  my ($finals, $rounds, $data,$iround) = @_;

#print "play_final_game\n";
  my ($a, $b) = @{$finals};

  if(ref $a eq "ARRAY") {
    # Need to recurse
    return get_result(play_final_game($a, $rounds, $data,$iround+1), play_final_game($b, $rounds, $data,$iround+1),$iround);

  } else {
    # drilled down to the region level
#print "  region $a v region $b\n";
    return get_result(play_game($rounds, $data->{$a},$iround+1), play_game($rounds, $data->{$b},$iround+1),$iround);
  }
}

sub play_game {
  my ($rounds, $data,$iround) = @_;

#print "play_game\n";
  my ($a,$b) = @{$rounds};

  if(ref $a eq "ARRAY") {
    # have to recurse
    return get_result(play_game($a, $data,$iround+1), play_game($b, $data,$iround+1),$iround);

  } else {
    # actually at a game here!
#print "  seed $a v seed $b\n";
    return get_result($data->[$a], $data->[$b],$iround);
  }
}

sub get_result {
  my ($a, $b,$i) = @_;

  my @ar = ((ref $a eq "ARRAY") ? @{$a}: $a);
  my @br = ((ref $b eq "ARRAY") ? @{$b}: $b);

  print "NEW GAME ($i):\n";

  my $r = undef;
  my @outcomes = (@ar, @br);

  foreach(@ar) {
    my $qa = $_;
    foreach(@br) {
      my $qb = $_;
      print "$qa   v   $qb\n";
      system("./rankings.pl $input_dur \"$qa\" \"$qb\"");
      print "\n";
    }
  }

  print "0 or 1 or ?  ";
  my $in = <STDIN>;
  chomp $in;
  $in = 0 if !$in;
  if($in > scalar @outcomes - 1) {
    $in = scalar @outcomes - 1;
  }
  $r = $outcomes[$in]; 
  


  print "\n";

  $game_data[$i] = [] if !defined $game_data[$i];
  push @{$game_data[$i]}, $r;

  return $r;
}


