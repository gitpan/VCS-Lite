# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
use VCS::Lite;

my $el1 = VCS::Lite->new('data/mariner.txt');

#01
isa_ok($el1,'VCS::Lite','Return from new, passed filespec');

my $el2 = VCS::Lite->new('data/marinerx.txt');

#02
ok(!$el1->diff($el1),'Compare with same returns empty array');

my $el3 = $el1->patch('data/marinerx.dif');

#03
isa_ok($el3,'VCS::Lite','Return from patch method');

#Uncomment for debugging
#open DIFF,'>diff1.out';
#print DIFF $diff;
#close DIFF;

my $out2 = $el2->text;
my $out3 = $el3->text;
is($out2, $out3, 'Patched file is the same as diff1b');