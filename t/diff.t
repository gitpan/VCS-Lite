
use strict;
use Test::More tests => 13;
use VCS::Lite;

my $el1 = VCS::Lite->new('data/mariner.txt');

#01
isa_ok($el1,'VCS::Lite','Return from new, passed filespec');

#02
is($el1->id,'data/mariner.txt','Correct name returned by id');

my $el2 = VCS::Lite->new('data/marinerx.txt');

#03
ok(!$el1->delta($el1),'Compare with same returns empty array');

my $dt1 = $el1->delta($el2);

#04
isa_ok($dt1,'VCS::Lite::Delta','Delta return');

#05
my @id = $dt1->id;
is_deeply(\@id,['data/mariner.txt',
		'data/marinerx.txt'],
		'id method of delta returns correct ids');

#06
my @hunks = $dt1->hunks;
is_deeply(\@hunks,
	[
	    [
	    	['-', 3, "Now wherefore stopp'st thou me?\n"],
	    	['+', 3, "Now wherefore stoppest thou me?\n"],
	    ],[
	    	['-', 20, "The Wedding-Guest sat on a stone:\n"],
	    	['-', 21, "He cannot chuse but hear;\n"],
	    	['-', 22, "And thus spake on that ancient man,\n"],
	    	['-', 23, "The bright-eyed Mariner.\n"],
	    	['-', 24, "\n"],
	    ],[
	    	['+', 32, "Wondering about the wretched loon\n"],
	    ],[
	    	['-', 94, "Whiles all the night, through fog-smoke white,\n"],
	    	['-', 95, "Glimmered the white Moon-shine.\n"],
	    	['+', 90, "While all the night, through fog-smoke white,\n"],
	    	['+', 91, "Glimmered the white Moonshine.\n"],
	    ]
	], 'Full comparison of hunks');

my $diff = $dt1->diff;

#07
ok($diff, 'Diff returns differences');

#Uncomment for debugging
#open DIFF,'>diff1.out';
#print DIFF $diff;
#close DIFF;

my $results = do { local (@ARGV, $/) = 'data/marinerx.dif'; <> };

#08
is($diff, $results, 'Diff matches expected results (diff)');

my $el3 = VCS::Lite->new('data/marinery.txt');
$diff = $el1->diff($el3);	# old form of call

#09
ok($diff, 'Diff returns differences');

#Uncomment for debugging
#open DIFF,'>diff2.out';
#print DIFF $diff;
#close DIFF;

$results = do { local (@ARGV, $/) = 'data/marinery.dif'; <> };

#10
is($diff, $results, 'Diff matches expected results (diff)');

my $udiff = $dt1->udiff;

#11
ok($udiff, 'udiff returns differences');

#Uncomment for debugging
#open DIFF,'>diff3.out';
#print DIFF $udiff;
#close DIFF;

$results = do { local (@ARGV, $/) = 'data/marinerx1.udif'; <> };

#12
is($udiff, $results, 'Diff matches expected results (udiff)');

$dt1 = $el1->delta($el2, window => 3);
$udiff = $dt1->udiff;

$results = do { local (@ARGV, $/) = 'data/marinerx.udif'; <> };

#13
is($udiff, $results, 'Diff matches expected results (udiff, 3 window)');

#Uncomment for debugging
#open DIFF,'>diff4.out';
#print DIFF $udiff;
#close DIFF;
