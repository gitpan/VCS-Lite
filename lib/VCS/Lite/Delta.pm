package VCS::Lite::Delta;

use strict;
use warnings;
our $VERSION = '0.01';

=head1 NAME

VCS::Lite::Delta - VCS::Lite differences

=head1 SYNOPSIS

  use VCS::Lite;

  # diff

  my $lit = VCS::Lite->new('/home/me/foo1.txt');
  my $lit2 = VCS::Lite->new('/home/me/foo2.txt');
  my $difftxt = $lit->delta($lit2)->diff;
  print OUTFILE $difftxt;

  # patch

  my $delt = VCS::Lite::Delta->new('/home/me/patch.diff');
  my $lit3 = $lit->patch($delt);
  print OUTFILE $lit3->text;

  # merge

  my $lit4 = $lit->merge($lit->delta($lit2),$lit->delta($lit3));
  print OUTFILE $lit4->text;

=head1 DESCRIPTION

This module provides a Delta class for the differencing functionality of
VCS::Lite

=head2 new

The underlying object of VCS::Lite::Delta is an array of difference 
chunks such as that returned by Algorithm::Diff. 

The constructor takes the following forms:

  my $delt = VCS::Lite::Delta->new( '/my/file.diff',$sep); # File name
  my $delt = VCS::Lite::Delta->new( \*FILE,$sep);	# File handle
  my $delt = VCS::Lite::Delta->new( \$string,$sep); # String as scalar ref
  my $delt = VCS::Lite::Delta->new( \@foo, $id1, $id2) # Array ref

$sep here is a regexp by which to split strings into tokens. 
The default is to use the natural perl mechanism of $/ (which is emulated 
when not reading from a file).  

=head2 diff

  print OUTFILE $delt->diff

This generates a standard diff format, for example:

4c4
< Now wherefore stopp'st thou me?
---
> Now wherefore stoppest thou me?

=head1 COPYRIGHT

Copyright (c) Ivor Williams, 2003

=head1 LICENCE

You may use, modify and distribute this module under the same terms 
as Perl itself.

=head1 SEE ALSO

L<Algorithm::Diff>.

=cut

use Carp;

sub new {
	my $class = shift;
	my $src = shift;

# DWIM logic, based on $src parameter.

# Case 0: string. Use $id as file name, becomes case 2
	if (!ref $src) {
		open my $fh,$src or croak("failed to open '$src': $!");
		$src = $fh;
	}
	my $atyp = ref $src;

# Case 1: $src is arrayref
	return bless [$_[0],$_[1],@$src],$class if $atyp eq 'ARRAY';

	my $sep = shift;
	local $/ = $sep if $sep;
	$sep ||= qr(^)m;
	my @diff;

# Case 2: $src is globref (file handle) - slurp file
	if ($atyp eq 'GLOB') {
		@diff = <$src>;
	}
# Case 3: $src is scalar ref (string)
	elsif ($atyp eq 'SCALAR') {
		@diff = split $sep,$$src;
	}


# Case otherwise is an error.
	else {
		croak "Invalid argument to VCS::Lite::Delta::new";
	}

# If we have reached this point, we have been passed something in a
# text/diff format. It could be diff or udiff format.

	my @out = @_[0,1];

	if ($diff[0] =~ /^---/) {		# udiff format
		my $state = 'inputdef';
		my ($a_line,$a_count,@a_hunk,$b_line,$b_count,@b_hunk);
		for my $lin (0..$#diff) {
			local $_ = $diff[$lin];

# inputdef = --- and +++ to identify the files being diffed

			if ($state eq 'inputdef') {
				$out[0] = $1 if /^---	# ---
						\s
						(\S+)/x;	# file => $1
				$out[1] = $1 if /^\+{3}	# +++
						\s
						(\S+)/x;	# file => $1
				$state = 'patch' if /^\@\@/;
			}

# patch expects @@ -a,b +c,d @@

			if ($state eq 'patch') {
				next unless /^\@\@
						\s+
						-
						(\d+)	# line of file 1 => $1
						,
						(\d+)	# count of file 1 => $2
						\s*
						\+
						(\d+)	# line of file 2 => $3
						,
						(\d+)	# count of file 2 => $4
						\s*
						\@\@/x;
				$a_line = $1 - 1;
				$a_count = $2;
				$b_line = $3 - 1;
				$b_count = $4;
				$state = 'detail';
				next;
			}

# detail expects [-+ ]line of text

			if ($state eq 'detail') {
				my $ind = substr $_,0,1,'';
				_error($lin,'Bad diff'), return undef
					unless $ind =~ /[ +\-]/;
#[- ]line, add to @a_hunk
				if ($ind ne '+') {
					push @a_hunk, ['-', $a_line++, $_];
					$a_count--;
					_error($lin,'Too large diff'), return undef
						if $a_count < 0;
				}

#[+ ]line, add to @b_hunk
				if ($ind ne '-') {
					push @b_hunk, ['+', $b_line++, $_];
					$b_count--;
					_error($lin,'Too large diff'), return undef
						if $b_count < 0;
				}
# are we there yet, daddy?
				if (!$a_count and !$b_count) {
					push @out, [@a_hunk, @b_hunk];
					@a_hunk = @b_hunk = ();
					$state = 'patch';
				}
			}
		} 	# next line of patch
		return bless \@out, $class;
	}

# not a udiff mode patch, assume straight diff mode

	my $state = 'patch';
	my ($a_line,$a_count,@a_hunk,$b_line,$b_count,@b_hunk);
	for my $lin (0..$#diff) {
		local $_ = $diff[$lin];

# patch expects ww,xx[acd]yy,zz style

		if ($state eq 'patch') {
			next unless /^(\d+)	# start line of file 1 => $1
				(?:,(\d+))?	# end line of file 1 => $2
				([acd])		# Add, change, delete => $3
				(\d+)		# start line of file 2 => $4
				(?:,(\d+))?	# end line of file 2 => $5
				/x;
				$a_line = $1 - 1;
				$a_count = $2 ? ($2 - $a_line) : 1;
				$b_line = $4 - 1;
				$b_count = $5 ? ($5 - $b_line) : 1;
				$a_count = 0 if $3 eq 'a';
				$b_count = 0 if $3 eq 'd';
				$state = 'detail';
				next;
		}

# detail expects < lines --- > lines

		if ($state eq 'detail') {
			next if /^---/;		# ignore separator
			my $ind = substr $_,0,2,'';
			_error($lin,'Bad diff'), return undef
				unless $ind =~ /[<>] /;

# < line goes to @a_hunk
			if ($ind eq '< ') {
				push @a_hunk, ['-', $a_line++, $_];
				$a_count--;
				_error($lin,'Too large diff'), return undef
					if $a_count < 0;
			}

# > line goes to @b_hunk
			if ($ind eq '> ') {
				push @b_hunk, ['+', $b_line++, $_];
				$b_count--;
				_error($lin,'Too large diff'), return undef
					if $b_count < 0;
			}
# are we there yet, daddy?
			if (!$a_count and !$b_count) {
				push @out, [@a_hunk, @b_hunk];
				@a_hunk = @b_hunk = ();
				$state = 'patch';
			}
		}
	}
	return bless \@out, $class;
}

# Error handling, use package vars to control it for now.

use vars qw($error_action $error_msg $error_line);

sub _error {
	($error_line,my $msg) = @_;

	$error_msg = "Line $error_line: $msg";

	goto &$error_action if ref($error_action) eq 'CODE';
	confess $error_msg if $error_action eq 'raise';

	print STDERR $error_msg,"\n" unless $error_action eq 'silent';
}

sub diff {
	my $self = shift;
	my $sep = shift || '';

	my $off = 0;

# included diff_hunk is local to this sub, i.e. private

	sub diff_hunk {

		my $sep = shift;
		my $r_line_offset = shift;
		
		my @ins;
		my ($ins_firstline,$ins_lastline) = (0,0);
		my @del;
		my ($del_firstline,$del_lastline) = (0,0);
		my $op;

# construct @ins and @del from hunk

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
		
# Work out whether we are a, c or d

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
		
# Make the header line

		my $outstr = "$del_firstline,$del_lastline$op$ins_firstline,$ins_lastline\n";
		$outstr =~ s/(^|\D)(\d+),\2(?=\D|$)/$1$2/g;

# < deletions
		for (@del) {
			$outstr .= '< ' . $_ . $sep;
		}
		
# ---
		$outstr .= "---\n" if @ins && @del;
		
# > insertions
		for (@ins) {
			$outstr .= '> ' . $_ . $sep;
		}
	
		$outstr;
	} #end of sub diff_hunk;

# back to sub diff
	
	my ($id1,$id2,@d) = @$self;
	
	join '',map {diff_hunk($sep,\$off,@$_)} @d;
}

sub udiff {
	my $self = shift;
	my $sep = shift || '';

	my ($in,$out,@diff) = @$self;

# Header with file names

	my @out = ("--- $in \n","+++ $out \n");

	my $offset = 0;

	for (@diff) {
		my @t1 = grep {$_->[0] eq '-'} @$_;
		my @t2 = grep {$_->[0] eq '+'} @$_;

# Work out base line numbers in both files

		my $base1 = @t1 ? $t1[0][1] : $t2[0][1] - $offset;
		my $base2 = @t2 ? $t2[0][1] : $t1[0][1] + $offset;
		$base1++; $base2++;	# Our lines were 0 based
		$offset += @t2 - @t1;
		my $count1 = @t1;
		my $count2 = @t2;

# Header line
		push @out, "@@ -$base1,$count1 +$base2,$count2 @@\n";

# Use Algorithm::Diff::sdiff to munge out any lines in common inside
# the hunk
		my @txt1 = map {$_->[2]} @t1;
		my @txt2 = map {$_->[2]} @t2;

		my @ad = Algorithm::Diff::sdiff(\@txt1,\@txt2);
		my @defer;

# for each subhunk, we want all the file1 lines first, then all the file2 lines

		for (@ad) {
			my ($ind,$txt1,$txt2) = @$_;

# we want to flush out the + lines when we run off the end of a 'c' section

			(push @out,@defer),@defer=() unless $ind eq 'c';

# unchanged lines, just wack 'em out
			(push @out,' '.$txt1),next if $ind eq 'u';

# output original line (- line)
			push @out,'-'.$txt1 unless $ind eq '+';

# defer changed + lines
			push @defer,'+'.$txt2 unless $ind eq '-';
		}

# and flush at the end
		push @out,@defer;
	}
	wantarray ? @out : join $sep,@out;
}

sub merge {
	my $d1 = shift;
	my $d2 = shift;

	my $pkg = ref $d1;
	$d2 = $pkg->new($d2,@_) unless ref $d2;

	my ($d1_from,$d1_to,@d1) = @$d1;
	my ($d2_from,$d2_to,@d2) = @$d2;

	my $confl = shift || \&default_hlr;

	my (%original,%changed);

	for (@d1, @d2) {
		if ($_->[0][0] eq '+') {
			$changed{$_->[0][1]}++;
			next;
		}
			
		for (@$_) {
			next unless $_->[0] eq '-';
			$original{$_->[1]} = $_->[2];
			$changed{$_->[1]}++;
		}
	}
	my @out;
	my $o_from = ($d1_from eq $d2_from) ? $d1_from : "$d1_from|$d2_from";
	my $o_to = "$d1_to|$d2_to";

	my ($start,$end,$prev,$ifconf);

	for (sort keys %changed) {
		$prev ||= $_;
		if ($prev != $_ - 1) {
			push @out, $d1->_merge_hunk($d2,$start,$prev,\%original,
				$ifconf,$confl)
				if defined($start);
			$start = $prev if $prev ne $_ - 1;
		}
		$ifconf++ if $changed{$_} > 1;
	}
	push @out, $d1->_merge_hunk($d2,$start,$prev,\%original,$ifconf,$confl);

	$pkg->new(\@out,$o_from,$o_to);
}

sub _merge_hunk {
	my ($delt1,$delt2,$from,$to,$orig,$conflict,$handler) = @_;

	my ($d1f0,$d1f1,@d1) = @$delt1;
	my ($d2f0,$d2f1,@d2) = @$delt2;

	my @out;
	my (@orig,@chg1,@chg2,@merged);
	my ($cur1,$cur2);
	#@d1 = map {@$_} @d1;
	#@d2 = map {@$_} @d2;
	my $off1 = 0;
	my $off2 = 0;
	for ($from..$to) {
		while (@d1) {
			$cur1 ||= shift @d1;
			last if $cur1->[-1][1] >= $_;
			$off1 += ($_->[0] eq '+') ? 1 : -1
				for @$cur1;
			$cur1 = shift @d1;
		}
	#	if ($cur1->[0][1] == $_) {
			
		while (@d2) {
			$cur2 ||= shift @d2;
			last if $cur2->[-1][1] >= $_;
			$off2 += ($_->[0] eq '+') ? 1 : -1
				for @$cur2;
			$cur2 = shift @d2;
		}
		push @orig,$orig->{$_} if exists $orig->{$_};
	}
}
	
1;
