# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
use VCS::Lite;

my $el1 = VCS::Lite->new('data/mariner.txt');

#01
isa_ok($el1,'VCS::Lite','Return from new, passed filespec');

my $el2 = VCS::Lite->new('data/marinery.txt');

#02
ok(!$el1->diff($el1),'Compare with same returns empty array');

my $diff = $el1->diff($el2);

#03
ok($diff, 'Diff returns differences');

#Uncomment for debugging
#open DIFF,'>diff1.out';
#print DIFF $diff;
#close DIFF;

my $results = do { local (@ARGV, $/) = 'data/marinery.dif'; <> }; # slurp entire file

is($diff, $results, 'Diff matches expected results');