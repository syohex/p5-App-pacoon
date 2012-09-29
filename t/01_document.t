use strict;
use warnings;
use Test::More;

use App::pacoon;
use t::Util qw/is_contained/;

subtest 'document of perlfoo' => sub {
    my $app = App::pacoon->new;
    $app->_set_perlpods;

    ok is_contained($app->{perlpods}, 'perldoc'), 'found perldoc';
    ok is_contained($app->{perlpods}, 'perlsyn'), 'found perlsyn';
};

done_testing;
