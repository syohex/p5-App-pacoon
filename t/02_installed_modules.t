use strict;
use warnings;
use Test::More;

use App::pacoon;
use t::Util qw/is_contained/;

subtest 'installed module' => sub {
    my $app = App::pacoon->new;
    $app->_set_installed_modules;
    ok is_contained($app->{modules}, 'Encode'), 'has Encode';
};

done_testing;
