#!/usr/bin/perl

use strict;
use warnings;
use POSIX "fmod";

# parameters
#  diameter of the disc (in decimal inches)
#  page height (in decimal inches of usable space)
#  fwd degree center (in decimal degrees)
#  markings list:
#    modulus-height     --- non-numbers, just marks
#    modulusnheight     --- numbers and marks
#    (height is given in decimal inches; modulus is given in decimal degrees)


our $PI = 3.141592653589793;

my $disc_diameter = shift || die "ERROR: Need a disc diameter\n";
my $page_height = shift || die "ERROR: Need a page height\n";
my $degree_center = shift // die "ERROR: Need a degree center\n";
my $outfiles = shift || die "ERROR: Need to specify an output file base\n";
my @markings = @ARGV;

my $rht = 1.0;
my $aht = 2.0;
my $tht = 4.5;
my $thread_width = "thin";

my $svg_out = $outfiles.".svg";
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
my $num_marks = int($page_height / $smallest_width);
my $start_fwd_mark = $degree_center - int($num_marks / 2) * $smallest_degs;
my $final_fwd_mark = $start_fwd_mark + $num_marks * $smallest_degs;

# figure out how wide the first "inch" should be
my $first_inch_width = fmod($page_height, 1.0);


################
open CSSO, ">",$css_out or die "ERROR: Can't open $css_out for writing\n";

# figure out what to print out to the .css file for styles

print CSSO <<"EOM";

EOM

foreach(sort {$a <=> $b} keys %real_marks) {
    my $mo = $_;
    my $mc = $real_marks{$mo}->{mark_class};
    my $ht = $real_marks{$mo}->{height};
    my $fht = $rht - $ht;
    print CSSO << "EOM";

EOM

}



close(CSSO);

################


open SVGO, ">",$svg_out or die "ERROR: Can't open $svg_out for writing\n";



print SVGO "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n";
print SVGO "<?xml-stylesheet href='$css_out' type='text/css' ?>\n";
print SVGO "<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.0//EN\" \"http://www.w3.org/TR/REC-SVG-20010904/DTD/svg10.dtd\">\n";
print SVGO "<svg height=\"${page_height}in\" width=\"8in\">\n";

print SVGO "    <title>Angular Ruler ($degree_center)</title>\n\n";
print SVGO "    <!-- Disc-diameter: $disc_diameter -->\n";
print SVGO "    <!-- Page-height: $page_height -->\n";
print SVGO "    <!-- Fwd-degree-center: $degree_center -->\n";
print SVGO "    <!-- Degree-width: $degree_width -->\n";
print SVGO "    <!-- Mark-space-degrees: $smallest_degs -->\n";
print SVGO "    <!-- Mark-space-inches: $smallest_width -->\n";
print SVGO "    <!-- Fwd-degree-start: $start_fwd_mark -->\n";
print SVGO "    <!-- Fwd-degree-end: $final_fwd_mark -->\n\n";

print SVGO "<g id='page_container'>";
print SVGO "<g id='alignment_container'>";

for(my $current_mark = $start_fwd_mark; $current_mark < $final_fwd_mark; $current_mark += $smallest_degs) {
    my $rules = findRules($current_mark);

    my $xloc = ($current_mark - $start_fwd_mark + $smallest_degs) * $degree_width;

    print SVGO     "<g class='align_holder'>";
    if($rules->{use_numbers}) {
	print SVGO "<!-- Align: $current_mark -->";
#	print SVGO "<g class='align_mark'></g>";
	print SVGO "<line y1='${xloc}in' x1='0in' y2='${xloc}in' x2='6in' stroke='black' strokeWidth='1px' />\n";
    } else {
#	print SVGO "<g class='align_space'></g>";
    }
    print SVGO     "</g>";
}

print SVGO         "</g>";
print SVGO "<g id='stretcher_container'>";

#print SVGO "<g class='first_inch_block'></g>";

for(my $cur_inch=0; $cur_inch < int($page_height); ++$cur_inch) {
#    print SVGO "<g class='later_inch_block'></g>";
    if($cur_inch % 2 == 0) {
#	print SVGO "<rect y='${cur_inch}in' x='2in' height='1in' width='4in' fill='#bbb' stroke='none' strokeWidth='0px' />\n";
    } else {
#	print SVGO "<rect y='${cur_inch}in' x='2in' height='1in' width='4in' fill='#888' stroke='none' strokeWidth='0px' />\n";
    }
}

print SVGO "</g>";
print SVGO         "<g id='ruler_container'>";


for(my $current_mark = $start_fwd_mark; $current_mark < $final_fwd_mark; $current_mark += $smallest_degs) {
    my $rules = findRules($current_mark);

    my $top_spot = 8.0 - $rules->{height};
    my $xloc = ($current_mark - $start_fwd_mark + $smallest_degs) * $degree_width;

    print SVGO     "<g class='mark_holder_$rules->{mark_class}'>";
    print SVGO     "<!-- $current_mark -->";
    # print SVGO     "<g class='filler'>";
    if($rules->{use_numbers}) {
    # 	print SVGO "<g class='fwd_label'>";
    # 	print SVGO "<span>";
    # 	print SVGO sprintf("%.0f",findFwd($current_mark));
    # 	print SVGO "</span>";
    # 	print SVGO "</g>";
    # 	print SVGO "<g class='rev_label'>";
    # 	print SVGO "<span>";
    # 	print SVGO sprintf("%.0f",findRev($current_mark));
    # 	print SVGO "</span>";
    # 	print SVGO "</g>";


	print SVGO "<text y='-7.50in' x='${xloc}in' transform='rotate(90)' style='fill:#888;text-anchor:middle;font-size:5pt;font-family:serif;' >";
	print SVGO sprintf("%.0f",findFwd($current_mark));
	print SVGO "</text>\n";
	print SVGO "<text y='-7.59in' x='${xloc}in' transform='rotate(90)' style='fill:#000;text-anchor:middle;font-size:5pt;font-family:serif;' >";
	print SVGO sprintf("%.0f",findRev($current_mark));
	print SVGO "</text>\n";
    }

    # print SVGO     "</g>";
#    print SVGO     "<g class='mark'></g>";
    print SVGO "<line y1='${xloc}in' x1='8in' y2='${xloc}in' x2='${top_spot}in' stroke='black' strokeWidth='1px' />\n";
    print SVGO     "</g>";
}
print SVGO     "</g>\n";
print SVGO     "</g>\n";
print SVGO         "</svg>\n";

close(SVGO);

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
