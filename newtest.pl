# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;

my $diffout = `scripts/vldiff.pl data/mariner.txt data/marinerx.txt`;
my $diffexpected = do {local (@ARGV,$/) = ('data/marinerx.dif'); <>;};
#01
cmp_ok($diffout,$diffexpected,"vldiff output matched expected");

$diffout = `scripts/vldiff.pl -u data/mariner.txt data/marinerx.txt`;
$diffexpected = do {local (@ARGV,$/) = ('data/marinerx.udif'); <>;};
#02
cmp_ok($diffout,$diffexpected,"vldiff -u output matched expected");

`scripts/vlpatch.pl --output marinerx.tmp data/mariner.txt data/marinerx.dif`;
my $patchout = do {local (@ARGV,$/) = ('marinerx.tmp'); <>;};
my $patchexpected = do {local (@ARGV,$/) = ('data/marinerx.txt'); <>;};
#03
cmp_ok($patchout,$patchexpected,"vlpatch output matched expected");

`scripts/vlmerge.pl --output marinerxy.tmp data/mariner.txt data/marinerx.txt data/marinery.txt`;
my $mergeout = do {local (@ARGV,$/) = ('marinerx.tmp'); <>;};
my $mergeexpected = do {local (@ARGV,$/) = ('data/marinerxy.txt'); <>;};

#04
cmp_ok($mergeout,$mergeexpected,"vlmerge output matched expected");
