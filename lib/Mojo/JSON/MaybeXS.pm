package Mojo::JSON::MaybeXS;

use strict;
use warnings;
use Mojo::Util 'monkey_patch';
use JSON::MaybeXS 'JSON';
use Mojo::JSON ();

our $VERSION = '0.006';

my $BINARY = JSON::MaybeXS->new(utf8 => 1, allow_nonref => 1,
	allow_unknown => 1, allow_blessed => 1, convert_blessed => 1);
my $TEXT = JSON::MaybeXS->new(utf8 => 0, allow_nonref => 1,
	allow_unknown => 1, allow_blessed => 1, convert_blessed => 1);
my $TRUE = JSON->true;
my $FALSE = JSON->false;

monkey_patch 'Mojo::JSON', 'encode_json', sub { $BINARY->encode(shift) };
monkey_patch 'Mojo::JSON', 'decode_json', sub { $BINARY->decode(shift) };

monkey_patch 'Mojo::JSON', 'to_json',   sub { $TEXT->encode(shift) };
monkey_patch 'Mojo::JSON', 'from_json', sub { $TEXT->decode(shift) };

monkey_patch 'Mojo::JSON', 'true',  sub () { $TRUE };
monkey_patch 'Mojo::JSON', 'false', sub () { $FALSE };

=head1 NAME

Mojo::JSON::MaybeXS - use JSON::MaybeXS as the JSON encoder for Mojolicious

=head1 SYNOPSIS

 use Mojo::JSON::MaybeXS;
 use Mojo::JSON qw/encode_json decode_json true false/;
 
 use Mojo::JSON::MaybeXS;
 use Mojolicious::Lite;
 
 package My::Mojo::App;
 use Mojo::JSON::MaybeXS;
 use Mojo::Base 'Mojolicious';

=head1 DESCRIPTION

L<Mojo::JSON::MaybeXS> is a monkey-patch module for using L<JSON::MaybeXS> in
place of L<Mojo::JSON> in a L<Mojolicious> application, or in a standalone
capacity. It must be loaded before L<Mojo::JSON> so the new functions will be
properly exported.

=head1 CAVEATS

L<JSON::MaybeXS> may load different modules behind the scenes depending on what
is available, and these modules have slightly different behavior from
L<Mojo::JSON> and occasionally from each other. References to the behavior of
L<JSON::MaybeXS> below are actually describing the behavior shared among the
modules it loads.

L<JSON::MaybeXS> is used with the options C<allow_nonref>, C<allow_unknown>,
C<allow_blessed>, and C<convert_blessed>. C<allow_nonref> allows encoding and
decoding of bare values outside of hash/array references, since L<Mojo::JSON>
does not prevent this, in accordance with
L<RFC 7159|http://tools.ietf.org/html/rfc7159>. The other options prevent the
encoder from blowing up when encountering values that cannot be represented in
JSON to better match the behavior of L<Mojo::JSON>; in most cases, where
L<Mojo::JSON> would stringify a reference, L<JSON::MaybeXS> with these settings
will encode it to C<null>. See below for more specifics.

As of this writing, the author has found the following incompatibilities:

=head2 Object Conversion

Both L<JSON::MaybeXS> and L<Mojo::JSON> will attempt to call the TO_JSON method
of a blessed reference to produce a JSON-friendly structure. If that method
does not exist, L<JSON::MaybeXS> will encode the object to C<null>, while
L<Mojo::JSON> will stringify the object.

 print encode_json([DateTime->now]);
 # Mojo::JSON: ["2014-11-30T04:31:13"]
 # JSON::MaybeXS: [null]

=head2 Unblessed References

L<JSON::MaybeXS> does not allow unblessed references other than to hashes,
arrays, or the scalar values C<0> and C<1>, and will encode them to C<null>.
L<Mojo::JSON> will treat all scalar references the same as references to C<0>
or C<1> and will encode them to C<true> or C<false> depending on their boolean
value. Other references (code, filehandle, etc) will be stringified.

 print encode_json([\'asdf', sub { 1 }]);
 # Mojo::JSON: [true,"CODE(0x11d1650)"]
 # JSON::MaybeXS: [null,null]

=head2 Escapes

L<Mojo::JSON> currently escapes the slash character C</> for security reasons,
as well as the unicode characters C<u2028> and C<u2029>, while L<JSON::MaybeXS>
does not. This does not affect decoding of the resulting JSON.

 print encode_json(["/\x{2028}/\x{2029}"]);
 # Mojo::JSON: ["\/\u2028\/\u2029"]
 # JSON::MaybeXS: ["/ / "]
 # Both decode to arrayref containing: "/\x{2028}/\x{2029}"

=head2 inf and nan

L<Mojo::JSON> encodes C<inf> and C<nan> to strings, whereas L<JSON::MaybeXS>
will encode them differently depending which module is loaded. If it loads
L<Cpanel::JSON::XS> (the default if available) version 3.0109 or greater, it
will encode them as C<null> or strings, depending on a compilation option (the
default is C<null>). However, L<JSON::XS> or L<JSON::PP> will encode them as
numbers (barewords) producing invalid JSON.

 print encode_json([9**9**9, -sin 9**9**9]);
 # Mojo::JSON: ["inf","nan"]
 # Cpanel::JSON::XS: [null,null] (or ["inf","nan"] if compiled with -DSTRINGIFY_INFNAN)
 # JSON::XS or JSON::PP: [inf,nan]

=head2 Upgraded Numbers

L<JSON::MaybeXS>, if using L<JSON::XS> or L<JSON::PP>, will attempt to guess if
a value to be encoded is numeric or string based on its last usage. Therefore,
using a variable containing C<13> in a string will cause it to be encoded as
C<"13"> even if the variable itself was not changed. L<Mojo::JSON> or
L<Cpanel::JSON::XS> version 3.0109 or greater will encode C<13> as C<13>
regardless of whether it has been used as a string.

 my ($num1, $num2) = (13, 14);
 my $str = "$num1";
 print encode_json([$num1, $num2, $str]);
 # Mojo::JSON or Cpanel::JSON::XS: [13,14,"13"]
 # JSON::XS or JSON::PP: ["13",14,"13"]

=head1 BUGS

This is a monkey-patch of one of a few possible modules into another, and they
have incompatibilities, so there will probably be bugs. Report any issues on
the public bugtracker.

=head1 AUTHOR

Dan Book, C<dbook@cpan.org>

=head1 CREDITS

Sebastian Riedel, author of L<Mojolicious>, for basic implementation.

=head1 COPYRIGHT AND LICENSE

Copyright 2014, Dan Book.

This library is free software; you may redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Mojo::JSON>, L<JSON::MaybeXS>, L<Cpanel::JSON::XS>, L<JSON::XS>, L<JSON::PP>

=cut

1;
