# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More qw(no_plan);
use VCS::Lite;

my @quurg = qw(yan tan tether mether pip);
my @quurg2 = @quurg;
my $el1 = VCS::Lite->new(\@quurg);
@quurg = ();

#01
isa_ok($el1,'VCS::Lite','Return from new, passed arrayref');

my @quurg3 = $el1->text;

#02
ok(eq_array(\@quurg2,\@quurg3), 'Array identical streamed');

my $el2 = VCS::Lite->new([qw(yan tan dongle tongle tock mether blunk)]);

#03
ok(!$el1->diff($el1,"\n"),'Compare with same returns empty array');

#04
ok($el1->diff($el2,"\n"), 'Diff returns differences');
