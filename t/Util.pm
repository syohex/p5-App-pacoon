package t::Util;
use strict;
use warnings;

use base qw/Exporter/;

our @EXPORT = qw/is_contained/;

sub is_contained {
    my ($array_ref, $elem) = @_;

    if ( grep { $_ eq $elem } @{$array_ref} ) {
        return 1;
    }

    return;
}

1;

__END__
