package Devel::DumpStack;
require Exporter;
require Devel::CallerItem;
use AutoLoader;

@ISA = qw(Exporter AutoLoader);
@EXPORT = qw(dump_stack);
@EXPORT_OK=qw(call_at_depth printable_arg caller2
	      dump_on_die stack_as_string);

1;
#__END__

package Devel::DumpStack;

sub caller2 {
    my($depth) = @_;
    $depth ||= 0;
    my $call = Devel::CallerItem->from_depth($depth + 1);
    $call ? $call->as_array() : undef;
}

sub printable_arg {
    my($arg,$print_level) = @_;
    Devel::CallerItem->printable_arg($arg,$print_level);
}

sub call_at_depth {
    my($depth,$print_level) = @_;
    $depth ||= 0;
    my $call = Devel::CallerItem->from_depth($depth + 1);
    $call ? $call->as_string($print_level) : undef;
}

sub dump_stack {
    my($depth,$indent,$print_level) = @_;
    $depth ||= 0;
    $indent ||= '';

    my($str,$i);
    for($i = $depth+1;defined($str = Devel::CallerItem->from_depth($i));$i++){
	$str = $str->as_string($print_level);
	syswrite(STDERR, $indent, length($indent));
	syswrite(STDERR, $str, length($str));
    }
}

sub stack_as_string {
    my($depth,$indent,$print_level) = @_;
    $depth ||= 0;
    $indent ||= '';

    my($s,$str,$i);
    for($i = $depth + 1;defined($s = Devel::CallerItem->from_depth($i));$i++){
	$str .= $indent . $s->as_string($print_level);
    }
    $str;
}


sub dump_on_die {
    my($print_level) = @_;
    require 5.001;
    $SIG{'__DIE__'} = sub {
	print STDERR "Stack at death was\n";
	dump_stack(1,'    ',$print_level);
    }
}

1;
__END__

=head1 NAME

Devel::DumpStack - Access to the current stack of subroutine calls,
and dumping the stack in a readable form. See also L<sigtrap>.

=head1 SYNOPSIS

Usage:

    use Devel::DumpStack ...;
    
    dump_stack($depth,$indent,$print_level); #Prints to STDERR
    $stack = stack_as_string($depth,$indent,$print_level);
    $call_string = call_at_depth($depth,$print_level);
    ($args,$pack,$file,$line,$sub,$has_args,$wantarray) = caller2($depth);
    
    $printable_arg = printable_arg($arg,$print_level);
    
    dump_on_die($print_level); #dumps stack to STDERR on a 'die'

=head1 DESCRIPTION

Provides functions to access and dump the current stack of subroutine calls.

=head2 Functions Available:

(Note that only 'dump_stack' is exported by default.)

=over 4

=item dump_stack(DEPTH, INDENT, PRINT_LEVEL)

=item dump_stack(DEPTH, INDENT)

=item dump_stack(DEPTH)

=item dump_stack()

This prints the current functions stack to STDERR.
DEPTH is the depth of the stack to print from - equivalent
to the depth in caller(). Note that you can use negative
numbers for DEPTH if you want to include the dump_stack
call and calls under it on the stack print.

PRINT_LEVEL is 0, 1 or 2, depending on the level of detail
you want printed out for arguments. See L<Devel::CallerItem>.

The lines printed are in one of the appropriate formats:

    $ = func(args) called from FILE line LINE;
    $ = &func called from FILE line LINE;
    @ = func(args) called from FILE line LINE;
    @ = &func called from FILE line LINE;

giving the context (scalar - $, array - @) and whether it was called
with arguments or without (&).

INDENT is a string which is appended to the beginning of each line
printed out.

=item stack_as_string(DEPTH, INDENT, PRINT_LEVEL)

=item stack_as_string(DEPTH, INDENT)

=item stack_as_string(DEPTH)

=item stack_as_string()

Exactly as dump_stack, but instead of printing to STDERR, returns
the stack as a string.

=item dump_on_die(PRINT_LEVEL)

=item dump_on_die()

Calling this function inserts a handler for any 'die' calls, so
that when a 'die' is called, the current stack is first printed
to STDERR before exiting the process. You probably don't want to
do this if you are die'ing in an eval. PRINT_LEVEL is as
above.

=item printable_arg(ANYTHING, PRINT_LEVEL)

=item printable_arg(ANYTHING)

Renders its argument printable. PRINT_LEVEL is as
above.

=item caller2(DEPTH)

=item caller2()

Returns exactly what caller returns, except that the reference
to the argument array for the call at that depth is prepended
to the array - i.e. the first element of the returned array
is a reference to the argument array of the function called at
depth DEPTH, and the subsequent elements are the elements returned
by caller, in the same order. Returns undef if there is no call
at depth DEPTH.

=item call_at_depth(DEPTH, PRINT_LEVEL)

=item call_at_depth(DEPTH)

=item call_at_depth()

Returns a string in the format as given in dump_stack above,
but just for the single function call at the given DEPTH.
PRINT_LEVEL is as above.

=back

=head1 EXAMPLE

The following is a simple example, and can be
executed using C<perl -x Devel/DumpStack.pm>

#!perl
    

    use Devel::DumpStack qw(dump_stack);
    
    $a='pp';
    $c = bless [], A;
    $d = [$c];
    $c->[0] = $d;
    sub a { dump_stack(0,'    ',1); print STDERR "\n";}
    sub c { $scalar_context =  a(@_)}
    sub b { c([44,[66,{'q','hi'},\$a],$c])}

    @arr_context = &b;
    
__END__

=head1 AUTHOR

Jack Shirazi

  Copyright (c) 1995 Jack Shirazi. All rights reserved.
  This program is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.

=head1 MODIFICATION HISTORY

Version 1.1, 31st July - JS

Extracted out the Devel::CallerItem module, and added various
functions and print level extensions. NOTE that the module produces
a slightly different effect from version 1.0 - the DEPTH parameters
are now all set to work as if the function being called is a
replacement for caller - this means that the depths in version 1.0
are 1 or 2 different from the versions in 1.1. I felt the change
was worth it - now all calls with DEPTH are consistent.

Base version, 1.0, 24th April - only posted to perl-porters - JS.

=cut
