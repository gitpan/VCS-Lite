
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 9;
use VCS::Lite;

my $el1 = VCS::Lite->new('data/mariner.txt');

#01
isa_ok($el1,'VCS::Lite','Return from new, passed filespec');

my $el2 = VCS::Lite->new('data/marinerx.txt');

#02
ok(!$el1->delta($el1),'Compare with same returns empty array');

my $dt1 = $el1->delta($el2);

#03
isa_ok($dt1,'VCS::Lite::Delta','Delta return');

my $diff = $dt1->diff;

#04
ok($diff, 'Diff returns differences');

#Uncomment for debugging
#open DIFF,'>diff1.out';
#print DIFF $diff;
#close DIFF;

my $results = do { local (@ARGV, $/) = 'data/marinerx.dif'; <> }; # slurp entire file

#05
is($diff, $results, 'Diff matches expected results');

my $el3 = VCS::Lite->new('data/marinery.txt');
my $diff = $el1->diff($el3);	# old form of call

#06
ok($diff, 'Diff returns differences');

#Uncomment for debugging
#open DIFF,'>diff2.out';
#print DIFF $diff;
#close DIFF;

my $results = do { local (@ARGV, $/) = 'data/marinery.dif'; <> }; # slurp entire file

#07
is($diff, $results, 'Diff matches expected results');

$udiff = $dt1->udiff;

#08
ok($udiff, 'udiff returns differences');

#Uncomment for debugging
#open DIFF,'>diff3.out';
#print DIFF $udiff;
#close DIFF;

my $results = do { local (@ARGV, $/) = 'data/marinerx1.udif'; <> }; # slurp entire file

#09
is($udiff, $results, 'Diff matches expected results');
