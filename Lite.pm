package VCS::Lite;

use strict;
use warnings;
our $VERSION = '0.01';

=head1 NAME

VCS::Lite - Minimal version control system

=head1 SYNOPSIS

  use VCS::Lite;
  
  # diff
  
  my $lit = VCS::Lite->new($fh1);
  my $lit2 = VCS::Lite->new($fh2);
  my $difftxt = $lit->diff($lit2);
  print OUTFILE $difftxt;
  
  # patch
  
  my $lit3 = $lit->patch($fh3);
  $lit3->save('~me/patched_file');
  
  # merge
  
  my $lit4 = $lit->merge($lit2,$lit3);
  $lit4->save('~me/merged_file');
  
=head1 DESCRIPTION

This module provides the functions normally associated with a version 
control system, but without needing or implementing a version control 
system. Applications include wikis, document management systems and 
configuration management.

It makes use of the module Algorithm::Diff. It provides the facility 
for basic diffing, patching and merging.

=head2 new

The underlying object of VCS::Lite is an array. The members of the 
array can be anything that a scalar can represent (including references 
to structures and objects). The default is for the object to hold 
an array of scalars as strings corresponding to lines of text. If 
you want other underlying types, it is normal to subclass VCS::Lite 
for reasons which will become apparent,

There are several forms of the parameter list that B<new> can take.

my $lite = VCS::Lite->new( \@foo);				#Array ref
my $lite = VCS::Lite->new( '/users/me/prog.pl',$sep);	#File name
my $lite = VCS::Lite->new( $fh1,$sep);				#File handle
my $lite = VCS::Lite->new( \&next, $p1, $p2...);	#Callback

In the Perl spirit of DWIM, new assumes that given an arrayref, 
you have already done all the work of making your list of whatevers. 
Given a string (filename) or a file handle, the file is slurped, 
reading each line of text into a member of the array. Given a 
callback, the routine is called successively with arguments $p1, 
$p2, etc. and is expected to return a scalar which is added (pushed 
on) to the array. $sep is an optional input record separator regexp - the 
default is to use $/.

=head2 text

my $foo = $lite->text;
my $bar = $lit2->text('|');
my @baz = $lit3->text

In scalar context, returns the equivalent of the file contents slurped 
(the optional separator parameter is used to join the strings together). 
In list context, returns the list of lines or records.

=head2 save

$lit3->save('~me/patched_file');

Save is the reverse operation to new, given a file name or file 
handle. The file is written out calling the object's serialize 
method for successive members. If you are subclassing, you can supply
your own serializer.

=head2 diff

my $difftxt = $lit->diff($lit2);

Perform the difference between two VCS::Lite objects.

Output is in ordinary diff format, e.g.:

827c828
<   my ($id, $name) = @_;
---
>   my ($id, $name, $prefix) = @_;

=head2 patch

my $lit3 = $lit->patch($fh3);

Applies a patch to a VCS::Lite object. Accepts a file handle or 
file name string. Reads the file in diff format, and applies it. 
Returns a VCS::Lite object for the patched source.

=head2 merge

my $lit4 = $lit->merge($lit2,$lit3,\&confl);

Performs the "parallelogram of merging". This takes three VCS::Lite 
objects - the base object and two change streams. Returns a 
VCS::Lite object with both sets of changes merged.

The third parameter to the method is a sub which is called 
whenever a merge conflict occurs. This needs to either resolve the 
conflict or insert the necessary text to highlight the conflict.

=head1 AUTHOR

I. P. Williams, E<lt>Ivor dot williams (at) tiscali dot co dot United KingdomE<gt>

=head1 SEE ALSO

L<Algorithm::Diff>.

=cut

use Carp;
use Algorithm::Diff qw(traverse_sequences);

sub new {
	my $class = shift;
	my $arg = shift;
	my $atyp = ref $arg;
	
	return bless [@$arg],$class if $atyp eq 'ARRAY';
	unless ($atyp) {
		open my $fh,$arg or croak("failed to open '$arg': $!");
		$arg = $fh;
	}
	
	return bless [<$arg>],$class if ref($arg) eq 'GLOB';
	
	croak "Invalid argument" if $atyp ne 'CODE';
	
	local $/ = shift if @_;
	
	my @temp;
	while (my $item=&$arg(@_)) {
		push @temp,$item;
	}
	
	bless \@temp,$class;
}

sub text {
	my ($self,$sep) = @_;
	
	$sep ||= '';
	
	wantarray ? @$self : join $sep,@$self;
}


sub diff {
	my ($lite1,$lite2,$sep) = @_;
	
	$sep ||= '';
	my $off = 0;

	sub diff_hunk {

		my $sep = shift;
		my $r_line_offset = shift;
		
		my @ins;
		my ($ins_firstline,$ins_lastline) = (0,0);
		my @del;
		my ($del_firstline,$del_lastline) = (0,0);
		my $op;

		for (@_) {
			my ($typ,$lno,$txt) = @$_;
			$lno++;
			if ($typ eq '+') {
				push @ins,$txt;
				$ins_firstline ||= $lno;
				$ins_lastline = $lno;
			} else {
				push @del,$txt;
				$del_firstline ||= $lno;
				$del_lastline = $lno;
			}
		}
		
		if (!@del) {
			$op = 'a';
			$del_firstline = $ins_firstline - $$r_line_offset - 1;
		} elsif (!@ins) {
			$op = 'd';
			$ins_firstline = $del_firstline + $$r_line_offset - 1;
		} else {
			$op = 'c';
		}
		
		$$r_line_offset += @ins - @del;
		
		$ins_lastline ||= $ins_firstline;
		$del_lastline ||= $del_firstline;
		
		my $outstr = "$del_firstline,$del_lastline$op$ins_firstline,$ins_lastline\n";
		$outstr =~ s/(^|\D)(\d+),\2(?=\D|$)/$1$2/g;
		for (@del) {
			$outstr .= '< ' . $_ . $sep;
		}
		
		$outstr .= "---\n" if @ins && @del;
		
		for (@ins) {
			$outstr .= '> ' . $_ . $sep;
		}
	
		$outstr;
	}

	
	my @d = Algorithm::Diff::diff($lite1,$lite2);
	
	join '',map {diff_hunk($sep,\$off,@$_)} @d;
}

sub patch {
	my ($self,$fil) = @_;
	my @out = @$self;
	my $pkg = ref $self;
	my $atyp = ref $fil;

	# Equality of two array references (contents)
	
	sub equal
	{
		my ($a,$b) = @_;
	
		return 0 if @$a != @$b;
	
		foreach (0..$#$a)
		{
			return 0 if $a->[$_] ne $b->[$_];
		}
	
		1;
	}

	unless ($atyp) {
		open my $fh,$fil or croak("failed to open '$fil': $!");
		$fil = $fh;
	}
	
	while (<$fil>) {
		/^(\d+)(?:,(\d+))?([acd])(\d+)(?:,(\d+))?$/ or 
			croak "Incorrect syntax for patch, line $.";
		my $from_a = $1;
		my $to_a = $2 || $1;
		my $from_b = $4;
		my $to_b = $5 || $4;
		my $op = $3;
		my @ins;
		if ($op eq 'a') {
			for ($from_b .. $to_b) {
				my $lin = <$fil>;
				croak "Incorrect syntax for patch, line $." unless $lin =~ s/^> //;
				push @ins,$lin;
			}
			
			splice @out,$from_b - 1,0,@ins;
			next;
		}
		
		if ($op eq 'd') {
			for ($from_a .. $to_a) {
				my $lin = <$fil>;
				croak "Incorrect syntax for patch, line $." unless $lin =~ s/^< //;
				croak "Patch failed at line $." if $lin ne $out[$from_b];
				splice @out,$from_b,1;
			}
			next;
		}
		
		if ($op eq 'c') {
			for ($from_a .. $to_a) {
				my $lin = <$fil>;
				croak "Incorrect syntax for patch, line $." unless $lin =~ s/^< //;
				croak "Patch failed at line $." if $lin ne $out[$from_b-1];
				splice @out,$from_b-1,1;
			}
			croak "Incorrect syntax for patch, line $." unless <$fil> =~ /^---/;
			for ($from_b .. $to_b) {
				my $lin = <$fil>;
				croak "Incorrect syntax for patch, line $." unless $lin =~ s/^> //;
				push @ins,$lin;
			}
			
			splice @out,$from_b - 1,0,@ins;
		}
	}
	$pkg->new(\@out);
}

sub merge {
	my ($self,$chg1,$chg2) = @_;
	my $pkg = ref $self;


	my %ins1;
	my $del1 = '';

	traverse_sequences( $self, $chg1, {
		MATCH => sub { $del1 .= ' ' },
		DISCARD_A => sub { $del1 .= '-' },
		DISCARD_B => sub { push @{$ins1{$_[0]}},$chg1->[$_[1]] },
			} );

	my %ins2;
	my $del2 = '';

	traverse_sequences( $self, $chg2, {
		MATCH => sub { $del2 .= ' ' },
		DISCARD_A => sub { $del2 .= '-' },
		DISCARD_B => sub { push @{$ins2{$_[0]}},$chg2->[$_[1]] },
			} );

# First pass conflict detection: deletion on file 1 and insertion on file 2

	$del1 =~ s(\-+){
		my $stlin = length $`;
		my $numdel = length $&;

		my @confl = map {exists $ins2{$_} ? ($_) : ()} 
			($stlin+1..$stlin+$numdel-1);
		@confl ? '*' x $numdel : $&;
	}eg;

# Now the other way round: deletion on file 2 and insertion on file 1

	$del2 =~ s(\-+){
		my $stlin = length $`;
		my $numdel = length $&;

		my @confl = map {exists $ins1{$_} ? ($_) : ()} 
			($stlin+1..$stlin+$numdel-1);
		@confl ? '*' x $numdel : $&;
	}eg;

# Conflict type 1 is insert of 2 into deleted 1, Conflict type 2 is insert of 1 into deleted 2
# @defer is used to hold the 'other half' alternative for the conflict

	my $conflict = 0;
	my $conflict_type = 0;
	my @defer;

	my @out;

	for (0..@$self) {

# Get details pertaining to current @f0 input line 
		my $line = $self->[$_];
		my $d1 = substr $del1,$_,1;
		my $ins1 = $ins1{$_} if exists $ins1{$_};
		my $d2 = substr $del2,$_,1;
		my $ins2 = $ins2{$_} if exists $ins2{$_};

# Insert/insert conflict. This is not a conflict if both inserts are identical.

		if ($ins1 && $ins2 && !&equal($ins1,$ins2)) {
			push @out, ('*'x20)."Start of conflict ".(++$conflict).
			"  Insert to Primary, Insert to Secondary ".('*'x60)."\n";

			push @out, @$ins1, ('*'x100)."\n", @$ins2;
			push @out, ('*'x20)."End of conflict ".$conflict.('*'x80)."\n";
		} elsif (!$conflict_type) {	#Insert/Delete conflict

# Normal insertion - may be from $ins1 or $ins2. Apply the inser and junk both $ins1 and $ins2

			$ins1 ||= $ins2;

			push @out, @$ins1 if defined $ins1;

			undef $ins1;
			undef $ins2;
		}

# Detect start of conflict 1 and 2

		if (!$conflict_type && $d1 eq '*') {
			push @out, ('*'x20)."Start of conflict ".(++$conflict).
			"  Delete from Primary, Insert to Secondary ".('*'x60)."\n";

			$conflict_type = 1;
		}

		if (!$conflict_type && $d2 eq '*') {
			push @out, ('*'x20)."Start of conflict ".(++$conflict).
			"  Delete from Secondary, Insert to Primary ".('*'x60)."\n";

			$conflict_type = 2;
		}

# Handle case where we are in an Insert/Delete conflict block already

		if ($conflict_type == 1) {
			if ($d1 eq '*') {

# Deletion block continues...
				push @defer,(@$ins2) if $ins2;
				push @defer,$line if !$d2;
			} else {

# handle end of block, dump out @defer and clear it

				push @out, ('*'x100)."\n",@defer;
				undef @defer;
				push @out, ('*'x20)."End of conflict ".$conflict.('*'x80)."\n";
				$conflict_type = 0;
			}
		}

		if ($conflict_type == 2) {
			if ($d2 eq '*') {

# Deletion block continues...
				push @defer,(@$ins1) if $ins1;
				push @defer,$line if !$d1;
			} else {

# handle end of block, dump out @defer and clear it

				push @out, ('*'x100),"\n", @defer;
				undef @defer;
				push @out, ('*'x20)."End of conflict ".$conflict.('*'x80)."\n";
				$conflict_type = 0;
			}
		}
		last unless defined $line;	# for end of file, don't want to push undef
		push @out, $line unless ($d1 eq '-' || $d2 eq '-') && !$conflict_type;
	}
	$pkg->new(\@out);
}


1;