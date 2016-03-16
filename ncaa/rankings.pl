#!/usr/bin/perl

use strict;
use warnings;
use Text::CSV;
use Data::Dumper;

my $input_dir = shift || die "ERROR: Need to specify input directory.\n";

my %metrics = ();

my @files = glob("$input_dir/rankings-????.*.csv");

foreach(@files) {
  my $fn = $_;
  my $m = $fn;
  $m =~ s/^.*rankings-[[:digit:]]{4}\.([^.]+)\.csv$/$1/;

#  print STDERR "Reading in metric [$m] from [$fn]\n";

  my $csv = Text::CSV->new({binary=>1}) or die "ERROR: Failed creating Text::CSV object\n";

  my $fh; 
  open $fh, "<:encoding(utf8)", $fn or die "ERROR: opening [$fn]\n";
  $csv->column_names($csv->getline($fh));
  $metrics{$m} = $csv->getline_hr_all($fh);
  close($fh);
}

my $field = undef;

my @field_files = glob("$input_dir/field-????*.csv");

foreach(@field_files) {
  my $fn = $_;
#  print STDERR "Reading in field file [$fn]\n";
  my $csv = Text::CSV->new({binary=>1}) or die "ERROR: Failed creating Text::CSV object\n";
  my $fh;
  open $fh, "<:encoding(utf8)", $fn or die "ERROR: opening [$fn]\n";
  $csv->column_names("region","location","seed","school","rank");
  $field = $csv->getline_hr_all($fh);
  close($fh);

}


my %teams = ();

foreach(keys %metrics) {
  my $m = $_;
  foreach(@{$metrics{$m}}) {
    my $r = $_;
    my $n = $r->{Name};
    $teams{$n} = {mcount=>0, Name=>$n} if !defined $teams{$n};
    ++$teams{$n}->{mcount};

    foreach(keys %{$r}) {
      my $k = $_;
      if(!defined $teams{$n}->{$k}) {
        $teams{$n}->{$k} = $r->{$k};
      } else {
        if(($k ne "Rank" && $k ne "RPG" && $k ne "Pct" && $k ne "Ratio") &&
           ($teams{$n}->{$k} ne $r->{$k})) {
          print "Metric $m, School $n, Field $k conflicts (old: [$teams{$n}->{$k}], new: [$r->{$k}].\n";
        } elsif($k eq "Pct" && $m eq "Won-Lost_Precentage") {
          $teams{$n}->{$k} = $r->{$k};
        }
      }
    }
  }
}

#print Dumper($field);

foreach(@{$field}) {
  my $t = $_->{school};
  my $seed = $_->{seed};
  my $rank = $_->{rank};

  print STDERR "ERROR: Unable to find team data for [$t]\n" if !defined $teams{$t};

  $teams{$t}->{tournament} = 1;
  $teams{$t}->{tseed} = $_->{seed};
  $teams{$t}->{trank} = $_->{rank};

#  print "$t $seed $rank $teams{$t}->{GM} $teams{$t}->{W} $teams{$t}->{L}\n";
}

# Now, we'll assume you specify some number of team names as additional arguments, and display everything we think is relevant there.

my @fields = ("Name","trank","tseed","GM","W","L","Pct","SCR MAR","PTS","OPP PTS","PPG","OPP PPG","FGA","FGM","FG%","OPP FGA","OPP FG","OPP FG%");
my @fwidth = (-20   ,-5     ,-5     ,-3  ,-3 ,-3 ,-4   ,-7       ,-6   ,-7       ,-4   ,-7       ,-6   ,-6   ,-4   ,-7       ,-7      ,-7);
my @fwin   = (0     ,-1     ,-1     ,0   ,1  ,-1 ,1    ,1        ,1    ,-1       ,1    ,-1       ,1    ,1    ,1    ,-1       ,-1      ,-1);


my $i = 0;
foreach(@fields) {
  my $suf = ($fields[$i] eq "Name") ? "":" ";
  printf "$suf%*s", $fwidth[$i],$_;
  ++$i;
}
print "\n";

my @interesting_teams = @ARGV;
@interesting_teams = sort {$teams{$a}->{trank} <=> $teams{$b}->{trank}} grep {defined $teams{$_}->{tournament}} keys %teams if(! scalar @interesting_teams);

my @fbest = ();
my @fbestor = ();
my $b = 0;

foreach(@interesting_teams) {
  my $t = $_;
  die "ERROR: [$t] not a valid team name.\n" if !defined $teams{$t};
  die "ERROR: [$t] not in the tourney.\n" if !defined $teams{$t}->{tournament};

  my $j = 0;
  foreach(@fields) {
    my $f = $_;
    my $suf = ($fields[$j] eq "Name") ? "":" ";
    printf "$suf%*s", $fwidth[$j],$teams{$t}->{$f};

    if($fwin[$j] != 0) {
      my $x = $teams{$t}->{$f} * $fwin[$j];
      $fbest[$j] = $x if !defined $fbest[$j];
      $fbestor[$j] = [] if !defined $fbestor[$j];

      if($x > $fbest[$j]) {
        $fbest[$j] = $x;
        $fbestor[$j] = [$b];
      } elsif($x == $fbest[$j]) {
        push @{$fbestor[$j]}, $b;
      }
    }
    ++$j;
  }
  print "\n";
  ++$b;
}


for(my $q = 0; $q < scalar @fwin; ++$q) {
  my $suf = ($fields[$q] eq "Name") ? "":" ";
  if($fwin[$q] == 0) {
    printf "$suf%*s",$fwidth[$q], "";
  } else {
    printf "$suf%*s",$fwidth[$q], join('',@{$fbestor[$q]});
  }

}
print "\n";

exit(0);

