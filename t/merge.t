# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;
use VCS::Lite;

my $el1 = VCS::Lite->new('data/mariner.txt');

#01
isa_ok($el1,'VCS::Lite','Return from new, passed filespec');

my $el2 = VCS::Lite->new('data/marinerx.txt');
my $dt1 = $el1->delta($el2);

#02
isa_ok($dt1,'VCS::Lite::Delta','Delta returned');

my $el3 = VCS::Lite->new('data/marinery.txt');
my $dt2 = $el1->delta($el3);

#03
isa_ok($dt2,'VCS::Lite::Delta','Delta returned');

my $dt3 = $dt1->merge($dt2);

TODO: {
	todo_skip	'VCS::Lite::Delta->merge not yet finished', 3;
#04
isa_ok($dt3,'VCS::Lite::Delta','Return from merge method');

my $el4 = $el1->patch($dt3);

#05
isa_ok($el4,'VCS::Lite','Able to apply merge as patch');
my $merged = $el4->text;

#Uncomment for debugging
#open MERGE,'>merge1.out';
#print MERGE $merged;
#close MERGE;

my $results = do { local (@ARGV, $/) = 'data/marinerxy.txt'; <> }; # slurp entire file

#06
is($merged, $results, 'Merge matches expected results');
}
