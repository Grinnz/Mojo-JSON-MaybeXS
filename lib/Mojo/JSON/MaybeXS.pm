package Mojo::JSON::MaybeXS;

use strict;
use warnings;
use Mojo::Util 'monkey_patch';
use Mojo::JSON;
use JSON::MaybeXS;

our $VERSION = 0.003;

my $BINARY = JSON::MaybeXS->new(utf8 => 1, allow_nonref => 1,
	allow_blessed => 1, convert_blessed => 1);
my $TEXT = JSON::MaybeXS->new(utf8 => 0, allow_nonref => 1,
	allow_blessed => 1, convert_blessed => 1);

monkey_patch 'Mojo::JSON', 'encode_json', sub { $BINARY->encode(shift) };
monkey_patch 'Mojo::JSON', 'decode_json', sub { $BINARY->decode(shift) };

monkey_patch 'Mojo::JSON', 'to_json',   sub { $TEXT->encode(shift) };
monkey_patch 'Mojo::JSON', 'from_json', sub { $TEXT->decode(shift) };

monkey_patch 'Mojo::JSON', 'true',  sub () { JSON->true };
monkey_patch 'Mojo::JSON', 'false', sub () { JSON->false };

=head1 NAME

Mojo::JSON::MaybeXS - use JSON::MaybeXS as the JSON encoder for Mojolicious

=head1 SYNOPSIS

 use Mojo::JSON::MaybeXS;
 use Mojo::JSON qw/encode_json decode_json true false/;
 
 package My::Mojo::App;
 use Mojo::JSON::MaybeXS;
 use Mojo::Base 'Mojolicious';

=head1 DESCRIPTION

L<Mojo::JSON::MaybeXS> is a monkey-patch module for using L<JSON::MaybeXS> in
place of L<Mojo::JSON> in a L<Mojolicious> application. It must be loaded
before L<Mojo::JSON> so the new functions will be properly exported.

=head1 CAVEATS

L<JSON::MaybeXS> may load different modules depending on what is available, and
these modules have slightly different behavior from L<Mojo::JSON> and
occasionally from each other. As of this writing, the author has found the
following incompatibilities:

=head2 Boolean Stringification

If L<Cpanel::JSON::XS> is loaded by L<JSON::MaybeXS> (the default if available),
the L<Mojo::JSON/true> and L<Mojo::JSON/false> booleans will stringify to
C<"true"> and C<"false">. However, when using L<JSON::XS>, or L<JSON::PP>, they
will stringify to C<"1"> or C<"0">, like in L<Mojo::JSON>.

 print Mojo::JSON::false;
 # JSON::XS, JSON::PP, or Mojo::JSON: 0
 # Cpanel::JSON::XS: false

=head2 Object Conversion

Both L<JSON::MaybeXS> and L<Mojo::JSON> will attempt to call the TO_JSON method
of a blessed reference to produce a JSON-friendly structure. If that method
does not exist, L<JSON::MaybeXS> will encode the object to C<null>, while
L<Mojo::JSON> will stringify the object.

 print encode_json([DateTime->now]);
 # Mojo::JSON: ["2014-11-30T04:31:13"]
 # JSON::MaybeXS: [null]

=head2 Unblessed References

L<JSON::MaybeXS> does not allow unblessed references other than hash and array
references or references to the integers C<0> and C<1>, and will throw an
exception if attempting to encode one. L<Mojo::JSON> will treat all scalar
references the same as references to C<0> or C<1> and will encode them to
C<true> or C<false> depending on their boolean value.

 print encode_json([\'asdf']);
 # Mojo::JSON: [true]
 # JSON::MaybeXS: dies

=head2 Escapes

L<Mojo::JSON> currently escapes the slash character C</> for security reasons,
as well as the unicode characters C<u2028> and C<u2029>, while L<JSON::MaybeXS>
does not. This does not affect decoding of the resulting JSON.

 print encode_json(["/\x{2028}/\x{2029"]);
 # Mojo::JSON: ["\/\u2028\/\u2029"]
 # JSON::MaybeXS: ["/ / "]
 # Both decode to arrayref containing: "/\x{2028}/\x{2029}"

=head2 inf and nan

L<Mojo::JSON> encodes C<inf> and C<nan> to strings, whereas L<JSON::MaybeXS>
will encode them as numbers (barewords) producing invalid JSON.

 print encode_json([9**9**9, -sin 9**9**9]);
 # Mojo::JSON: ["inf","nan"]
 # JSON::MaybeXS: [inf,nan]

=head2 Upgraded Numbers

L<JSON::MaybeXS> will attempt to guess if a value to be encoded is numeric or
string based on its last usage. Therefore, using a variable containing C<13> in
a string will cause it to be encoded as C<"13"> even if the variable itself was
not changed. L<Mojo::JSON> will encode C<13> as C<13> regardless of whether it
has been used as a string.

 my ($num1, $num2) = (13, 14);
 my $str = "$num1";
 print encode_json([$num1, $num2, $str]);
 # Mojo::JSON: [13,14,"13"]
 # JSON::MaybeXS: ["13",14,"13"]

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
