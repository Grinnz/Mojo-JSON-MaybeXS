requires 'perl'          => '5.010001';
requires 'JSON::MaybeXS' => '1.001'; # for hash constructor
requires 'Mojolicious'   => '5.66'; # for nullary true/false
recommends 'Cpanel::JSON::XS' => '3.0112'; # inf/nan handled correctly
test_requires 'Test::More' => '0.88'; # for done_testing
test_requires 'Scalar::Util';
author_requires 'Test::Without::Module' => '0.17';
