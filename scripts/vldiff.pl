#!/usr/local/bin/perl

use strict;
use warnings;

use VCS::Lite;
use Getopt::Long;

my $uflag = 0;
my $wintxt = '';

GetOptions(
	'unified+' => \$uflag,
	'window=s' => \$wintxt,
	);

if (@ARGV != 2) {
	print <<END;

Usage: $0 [options] file1 file2

Options can be:

	-u | --unified	output in diff -u format
	-w n | --window n	set window size to n lines either side
	-w m,n | --window m,n	set window to m lines before, n lines after
END
	exit;
}

my $el1 = VCS::Lite->new(shift @ARGV);
my $el2 = VCS::Lite->new(shift @ARGV);

my $win = 0;

if ($wintxt =~ /(\d+),(\d+)/) {
	$win = [$1,$2];
}
elsif ($wintxt =~ /(\d+)/ {
	$win = $1;
}

my $dt1 = $el1->delta($el2, window => $win);
my $diff = $uflag ? $dt1->udiff : $dt1->diff;

print $diff;
