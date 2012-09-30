use strict;
use warnings;
use Test::More;

use App::pacoon;
use JSON::XS;
use t::Util qw/is_contained/;

subtest 'full path of private method' => sub {
    my $out = '';
    open my $ofh, '>', \$out;

    my $app = App::pacoon->new( out => $ofh );
    $app->_output_method({
        full       => 1,
        visibility => 'private',
        modules    => [ 'Encode', 'Carp']
    });

    my $obj = decode_json $out;
    is $obj->{status}, 'success';

    ok is_contained($obj->{result}, 'Encode::_bytes_to_utf8'), 'Encode private method';
    ok is_contained($obj->{result}, 'Carp::_cgc'), 'Carp private method';

    close $ofh;
};

done_testing;
