# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 9;
use VCS::Lite;

my $el1 = VCS::Lite->new('data/mariner.txt');

#01
isa_ok($el1,'VCS::Lite','Return from new, passed filespec');

my $el2 = VCS::Lite->new('data/marinerx.txt');
my $dt1 = VCS::Lite::Delta->new('data/marinerx.dif',undef,'mariner.txt','marinerx.txt');

#02
isa_ok($dt1,'VCS::Lite::Delta','New delta');

my $el3 = $el1->patch($dt1);

#03
isa_ok($el3,'VCS::Lite','Return from patch method');

my $out2 = $el2->text;
my $out3 = $el3->text;

#Uncomment for debugging
#open PAT,'>patch1.out';
#print PAT $out3;
#close PAT;

#04
is($out2, $out3, 'Patched file is the same as marinerx');

my $dt2 = VCS::Lite::Delta->new('data/marinerx.udif',undef,'mariner.txt','marinerx.txt');

#05
isa_ok($dt2,'VCS::Lite::Delta','New delta');

my $el4 = $el1->patch($dt2);

#06
isa_ok($el4,'VCS::Lite','Patch applied');

my $out4 = $el4->text;

#07
is($out2, $out4, 'Patched file is the same as marinerx');

my $udiff = $dt2->udiff;

#08
ok($udiff, "udiff returns text");

#Uncomment for debugging
open PAT,'>patch2.out';
print PAT $udiff;
close PAT;

my $results = do { local (@ARGV, $/) = 'data/marinerx.udif'; <> }; # slurp entire file

$results =~ s/^\+\+\+.*\n//s;
$results =~ s/^---.*\n//s;
$udiff =~ s/^\+\+\+.*\n//s;
$udiff =~ s/^---.*\n//s;

#09
is($udiff,$results,'udiff output matches original udiff');
