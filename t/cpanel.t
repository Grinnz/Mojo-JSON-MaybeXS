use Mojo::Base -strict;

use Test::More;
use Mojo::JSON::MaybeXS;
use Mojo::ByteStream 'b';
use Mojo::JSON qw(decode_json encode_json false from_json j to_json true);
use Mojo::Util 'encode';

unless (eval { require Cpanel::JSON::XS; 1 }) {
	plan skip_all => 'No Cpanel::JSON::XS';
}

is(JSON::MaybeXS::JSON, 'Cpanel::JSON::XS', 'Correct JSON class');

# Errors
eval { decode_json 'test' };
like $@, qr/'true' expected/, 'right error';
eval { decode_json b('["\\ud800"]')->encode };
like $@, qr/malformed JSON string/, 'right error';
eval { decode_json b('["\\udf46"]')->encode };
like $@, qr/malformed JSON string/, 'right error';
eval { decode_json '[[]' };
like $@, qr/, or ] expected while parsing array/, 'right error';
eval { decode_json '{{}' };
like $@, qr/'"' expected/, 'right error';
eval { decode_json "[\"foo\x00]" };
like $@, qr/unexpected end of string while parsing JSON string/, 'right error';
eval { decode_json '{"foo":"bar"{' };
like $@, qr/, or } expected while parsing object\/hash/, 'right error';
eval { decode_json '{"foo""bar"}' };
like $@, qr/':' expected/, 'right error';
eval { decode_json '[[]...' };
like $@, qr/, or ] expected while parsing array/, 'right error';
eval { decode_json '{{}...' };
like $@, qr/'"' expected/, 'right error';
eval { decode_json '[nan]' };
like $@, qr/'null' expected/, 'right error';
eval { decode_json '["foo]' };
like $@, qr/unexpected end of string while parsing JSON string/, 'right error';
eval { decode_json '{"foo":"bar"}lala' };
like $@, qr/garbage after JSON object/, 'right error';
eval { decode_json '' };
like $@, qr/malformed JSON string/, 'right error';
eval { decode_json "[\"foo\",\n\"bar\"]lala" };
like $@, qr/garbage after JSON object/, 'right error';
eval { decode_json "[\"foo\",\n\"bar\",\n\"bazra\"]lalala" };
like $@, qr/garbage after JSON object/, 'right error';
eval { decode_json '["♥"]' };
like $@, qr/Wide character in subroutine entry/, 'right error';
eval { decode_json encode('Shift_JIS', 'やった') };
like $@, qr/malformed JSON string/, 'right error';
is j('{'), undef, 'syntax error';
eval { decode_json "[\"foo\",\n\"bar\",\n\"bazra\"]lalala" };
like $@, qr/garbage after JSON object/, 'right error';
eval { from_json "[\"foo\",\n\"bar\",\n\"bazra\"]lalala" };
like $@, qr/garbage after JSON object/, 'right error';

done_testing();
