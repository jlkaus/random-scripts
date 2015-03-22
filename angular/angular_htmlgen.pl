#!/usr/bin/perl

use strict;
use warnings;
use POSIX "fmod";

# parameters
#  diameter of the disc (in decimal inches)
#  page width (in decimal inches of usable space)
#  fwd degree center (in decimal degrees)
#  markings list:
#    modulus-height     --- non-numbers, just marks
#    modulusnheight     --- numbers and marks
#    (height is given in decimal inches; modulus is given in decimal degrees)


our $PI = 3.141592653589793;

my $disc_diameter = shift || die "ERROR: Need a disc diameter\n";
my $page_width = shift || die "ERROR: Need a page width\n";
my $degree_center = shift // die "ERROR: Need a degree center\n";
my $outfiles = shift || die "ERROR: Need to specify an output file base\n";
my @markings = @ARGV;

my $rht = 1.0;
my $aht = 2.0;
my $tht = 4.5;
my $thread_width = "thin";

my $xml_out = $outfiles.".xml";
my $css_out = $outfiles.".css";

die "ERROR: Need some markings specified\n" unless scalar @markings;

my $smallest_degs = 360;

our %real_marks = ();
foreach(@markings) {
    if(/^([[:digit:].]+)-([[:digit:].]+)$/) {
#	print "Found - marking [$_]\n";
	my $mo = $1;
	my $ht = $2;
	my $un = undef;
	my $mc = "mo_".sprintf("%03.0f",$mo*10);
	$real_marks{$mo}={ height=>$ht, mark_class => $mc};
	$smallest_degs = $mo if($mo < $smallest_degs);
    } elsif(/^([[:digit:].]+)n([[:digit:].]+)$/) {
#	print "Found n marking [$_]\n";
	my $mo = $1;
	my $ht = $2;
	my $un = 1;
	my $mc = "mo_".sprintf("%03.0f",$mo*10);
	$real_marks{$mo}={height=>$ht, use_numbers=>1, mark_class => $mc};
	$smallest_degs = $mo if($mo < $smallest_degs);
    } else {
	die "ERROR: Don't understand marking specifier [$_]\n";
    }
}


# ok, given we have a diameter, we can come up with a degree width
my $degree_width = $PI * $disc_diameter/ 360.0;
#printf("Degree width = %.6f\n", $degree_width);

my $smallest_width = $smallest_degs * $degree_width;

# now figure out how many marks can fit on the page.
my $num_marks = int($page_width / $smallest_width);
my $start_fwd_mark = $degree_center - int($num_marks / 2) * $smallest_degs;
my $final_fwd_mark = $start_fwd_mark + $num_marks * $smallest_degs;

# figure out how wide the first "inch" should be
my $first_inch_width = fmod($page_width, 1.0);


################
open CSSO, ">",$css_out or die "ERROR: Can't open $css_out for writing\n";

# figure out what to print out to the .css file for styles

print CSSO <<"EOM";

body {
  background: #fff;
  margin: 0;
  padding: 0;
  border: 0;
}

div#page_container {
  background: #fff;
  margin: 0;
  padding: 0;
  box-sizing: border-box;
  display: block;
  border: 0;
  width: ${page_width}in;
}

div#stretcher_container {
  background: #fff;
  margin: 0;
  padding: 0;
  box-sizing: border-box;
  display: block;
  border: 0;
  width: ${page_width}in;
  height: ${tht}in;
}

div.first_inch_block {
  background: #888;
  margin: 0;
  padding: 0;
  box-sizing: border-box;
  display: inline-block;
  border: 0;
  width: ${first_inch_width}in;
  height: ${tht}in;
}

div.later_inch_block:nth-of-type(odd) {
  background: #bbb;
  margin: 0;
  padding: 0;
  box-sizing: border-box;
  display: inline-block;
  border: 0;
  width: 1in;
  height: ${tht}in;
}

div.later_inch_block:nth-of-type(even) {
  background: #666;
  margin: 0;
  padding: 0;
  box-sizing: border-box;
  display: inline-block;
  border: 0;
  width: 1in;
  height: ${tht}in;
}

div#alignment_container {
  background: #fff;
  margin: 0;
  padding: 0;
  box-sizing: border-box;
  display: block;
  border: 0;
  width: ${page_width}in;
  height: ${aht}in;
}

div.align_holder {
  background: #fff;
  margin: 0;
  padding: 0;
  box-sizing: border-box;
  display: inline-block;
  border: 0;
  width: ${smallest_width}in;
  height: ${aht}in;
}

div.align_space {
  background: #fff;
  margin: 0;
  padding: 0;
  box-sizing: border-box;
  display: block;
  border: 0;
  width: ${smallest_width}in;
  height: ${aht}in;
}

div.align_mark {
  background: #fff;
  margin: 0;
  padding: 0;
  box-sizing: border-box;
  display: block;
  border: 0;
  border-left: ${thread_width} solid #000;
  width: ${smallest_width}in;
  height: ${aht}in;
}

div#ruler_container {
  background: #fff;
  margin: 0;
  padding: 0;
  box-sizing: border-box;
  display: block;
  border: 0;
  width: ${page_width}in;
  height: ${rht}in;
}

EOM

foreach(sort {$a <=> $b} keys %real_marks) {
    my $mo = $_;
    my $mc = $real_marks{$mo}->{mark_class};
    my $ht = $real_marks{$mo}->{height};
    my $fht = $rht - $ht;
    print CSSO << "EOM";



div.mark_holder_$mc {
  background: #fff;
  margin: 0;
  padding: 0;
  box-sizing: border-box;
  display: inline-block;
  border: 0;
  width: ${smallest_width}in;
  height: ${rht}in;
}

div.mark_holder_$mc div.filler {
  background: #fff;
  margin: 0;
  padding: 0;
  box-sizing: border-box;
  display: block;
  border: 0;
  width: ${smallest_width}in;
  height: ${fht}in;
}

div.mark_holder_$mc div.fwd_label {
  background: #fff;
  margin: 0;
  padding: 0;
  box-sizing: border-box;
  display: block;
  text-align: center;
  border: 0;
}

div.mark_holder_$mc div.fwd_label span {
  background: #fff;
  margin: 0;
  padding: 0;
  box-sizing: border-box;
/*  display: inline;*/
  border: 0;
  text-align: center;
  color: #000;
  font: 8pt serif;
  display: none;
}

div.mark_holder_$mc div.rev_label {
  background: #fff;
  margin: 0;
  padding: 0;
  box-sizing: border-box;
  display: block;
  text-align: center;
  border: 0;
}

div.mark_holder_$mc div.rev_label span {
  background: #fff;
  margin: 0;
  padding: 0;
  box-sizing: border-box;
/*  display: inline; */
  border: 0;
  text-align: center;
  color: #666;
  font: 8pt serif;
  display: none;
}

div.mark_holder_$mc div.mark {
  background: #fff;
  margin: 0;
  padding: 0;
  box-sizing: border-box;
  display: block;
  border: 0;
  border-left: ${thread_width} solid #000;
  width: ${smallest_width}in;
  height: ${ht}in;
}

EOM

}


# pretty much every div should use border-box, I think.

close(CSSO);

################


open XMLO, ">",$xml_out or die "ERROR: Can't open $xml_out for writing\n";



print XMLO "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n";
#print XMLO "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.1//EN\" \"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd\">\n";
#print XMLO "<!DOCTYPE html>\n";
print XMLO "<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\" lang=\"en\">\n";

print XMLO "  <head>\n";
print XMLO "    <title>Angular Ruler ($degree_center)</title>\n\n";
print XMLO "    <!-- Disc-diameter: $disc_diameter -->\n";
print XMLO "    <!-- Page-width: $page_width -->\n";
print XMLO "    <!-- Fwd-degree-center: $degree_center -->\n";
print XMLO "    <!-- Degree-width: $degree_width -->\n";
print XMLO "    <!-- Mark-space-degrees: $smallest_degs -->\n";
print XMLO "    <!-- Mark-space-inches: $smallest_width -->\n";
print XMLO "    <!-- Fwd-degree-start: $start_fwd_mark -->\n";
print XMLO "    <!-- Fwd-degree-end: $final_fwd_mark -->\n\n";
print XMLO "    <link rel='stylesheet' type='text/css' href='$css_out' />\n";

print XMLO "  </head>\n";

print XMLO "<body>";
print XMLO "<div id='page_container'>";
print XMLO "<div id='alignment_container'>";

for(my $current_mark = $start_fwd_mark; $current_mark < $final_fwd_mark; $current_mark += $smallest_degs) {
    my $rules = findRules($current_mark);

    print XMLO     "<div class='align_holder'>";
    if($rules->{use_numbers}) {
	print XMLO "<!-- Align: $current_mark -->";
	print XMLO "<div class='align_mark'></div>";
    } else {
	print XMLO "<div class='align_space'></div>";
    }
    print XMLO     "</div>";
}

print XMLO         "</div>";
print XMLO "<div id='stretcher_container'>";

print XMLO "<div class='first_inch_block'></div>";

for(my $cur_inch=0; $cur_inch < int($page_width); ++$cur_inch) {
    print XMLO "<div class='later_inch_block'></div>";
}

print XMLO "</div>";
print XMLO         "<div id='ruler_container'>";


for(my $current_mark = $start_fwd_mark; $current_mark < $final_fwd_mark; $current_mark += $smallest_degs) {
    my $rules = findRules($current_mark);

    print XMLO     "<div class='mark_holder_$rules->{mark_class}'>";
    print XMLO     "<!-- $current_mark -->";
    print XMLO     "<div class='filler'>";
    if($rules->{use_numbers}) {
	print XMLO "<div class='fwd_label'>";
	print XMLO "<span>";
	print XMLO sprintf("%.0f",findFwd($current_mark));
	print XMLO "</span>";
	print XMLO "</div>";
	print XMLO "<div class='rev_label'>";
	print XMLO "<span>";
	print XMLO sprintf("%.0f",findRev($current_mark));
	print XMLO "</span>";
	print XMLO "</div>";
    }

    print XMLO     "</div>";
    print XMLO     "<div class='mark'></div>";
    print XMLO     "</div>";
}

print XMLO         "</div>";
print XMLO         "</div>";
print XMLO         "</body>\n";

print XMLO         "</html>\n";

close(XMLO);

exit 0;

sub findRules {
    my ($val) = @_;
    my $val2 = findFwd($val);
    # %real_marks

    my $highest_mark = undef;
    foreach(sort { $a <=> $b} keys %real_marks) {
#	print "Looking at $_ with respect to $val2\n";
	if(($val2 == 0) || (fmod($val2,$_) < 0.000001)) {
	    $highest_mark = $_;
	}
    }

#    print "  Found $highest_mark\n";
    return $real_marks{$highest_mark};
}


sub findFwd {
    my ($val) = @_;
    # $val should be within -360 to +360, and we need to convert it to
    # something from 0 to +360


    while($val > 360) {
	$val -= 360;
    }

    while($val < 0) {
	$val += 360;
    }

    return $val;
}

sub findRev {
    my ($val) = @_;

    # $val should be within -360 to +360, and we need to reverse it and convert it to something from 0 to +360

    $val = 360 - $val;

    while($val > 360) {
	$val -= 360;
    }

    while($val < 0) {
	$val += 360;
    }


    return $val;
}
