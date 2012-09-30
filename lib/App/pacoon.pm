package App::pacoon;
use strict;
use warnings;
use 5.008_001;

use Carp ();
use Config;
use Class::Inspector;
use ExtUtils::Installed;
use JSON::XS;

our $VERSION = '0.01';

sub new {
    my ($class, %args) = @_;

    my $in  = delete $args{in}  || *STDIN;
    my $out = delete $args{out} || *STDOUT;

    bless {
        in       => $in,
        out      => $out,
        modules  => [],
        perlpods => [],
        json     => JSON::XS->new()->ascii(1),
    }, $class;
}

my @method_cache;

my %cmd_table = (
    modules => \&_output_modules,
    pods    => \&_output_pods,
    method  => \&_output_method,
);

sub _output_result {
    my ($self, $result) = @_;
    print {$self->{out}} $self->{json}->encode($result);
}

sub _output_method {
    my ($self, $option) = @_;

    my @options;
    my $is_full = 0;
    if ($option->{full}) {
        $is_full = 1;
        push @options, 'full';
    }

    my $visibility;
    if ($option->{visibility}) {
        $visibility = $option->{visibility};
        unless ($visibility) {
            my $msg = "Invalid visibility parameter: '$visibility'";
            $self->_output_result({ status => 'fail', result => $msg });
            return;
        }
    } else {
        $visibility = 'private';
    }
    push @options, $visibility;

    my $cache = $method_cache[$is_full];
    my @methods;
    for my $module (@{$option->{modules}}) {
        my $methods_ref;
        if (exists $cache->{$module}) {
            $methods_ref = @{ $cache->{$module} };
        } else {
            my $methods = $self->_collect_methods($module, @options);
            return unless $methods;

            $cache->{$module} = $methods;
            $methods_ref = $methods;
        }

        push @methods, @{ $methods_ref };
    }

    my $res;
    if (@methods) {
        $res = { status => 'success', result => \@methods };
    } else {
        my $msg = "No methods found";
        $res = { status => 'fail', result => $msg };
    }

    $self->_output_result($res);
}

sub _collect_methods {
    my ($self, $module, @options) = @_;

    eval "require $module; 1"; ## no critic
    if ($@) {
        my $msg = "Error: not found module '$module'";
        $self->_output_result({ status => 'fail', result => $msg});
        return;
    }

    Class::Inspector->methods($module, @options);
}

sub _output_modules {
    my $self = shift;
    $self->_output_result({ status => 'success', result => $self->{modules} });
}

sub _output_pods {
    my $self = shift;
    $self->_output_result({ status => 'success', result => $self->{perlpods} });
}

sub run {
    my $self = shift;

    $self->_init;

    my ($json, $in) = ($self->{json}, $self->{in});
    my $chunk_size = 4096;
    while (sysread $in, my $buf, $chunk_size) {
        for my $req ( $json->incrparse($buf) ) {
            next unless _valid_request($req);

            my $cmd = $req->{command};
            $cmd_table{$cmd}->($self, $req->{option});
        }
    }

    while (my $line = <$in>) {
        chomp $line;
        next if $line eq '';

        unless ($line =~ m{^([^:]+):(.+)$}) {
            Carp::carp("Invalid format: 'Command:Arguments'($line)");
            next;
        }

        my ($cmd, $arg) = ($1, $2);
        my @args = split /\t/, $arg;
        last if $cmd eq 'quit';

        unless (exists $cmd_table{$cmd}) {
            Carp::carp("Error:Unknown command '$cmd'");
            next;
        }

        $cmd_table{$cmd}->($self, @args);
    }
}

sub _validate_request {
    my ($self, $req) = @_;

    my $cmd = $req->{command};
    unless (defined $cmd) {
        my $msg = 'Command not defined';
        $self->_output_result({ status => 'fail', result => $msg });
        return;
    }

    unless ($cmd =~ m{^(?:modules|pods|method)$}) {
        my $msg = "Invalid command: '$cmd'";
        $self->_output_result({ status => 'fail', result => $msg });
    }

    return 1;
}

sub _init {
    my $self = shift;

    $self->_set_installed_modules;
    $self->_set_perlpods;
}

sub _set_installed_modules {
    my $self = shift;
    $self->{modules} = [ ExtUtils::Installed->new->modules ];
}

sub _set_perlpods {
    my $self = shift;

    my $dir = File::Spec->catfile($Config{privlibexp}, 'pod');
    my @perldocs = do {
        opendir my $dfh, $dir or die "Can't opendir $dir: $!";
        my @pods = map { s/\.pod$//; $_ } (grep /\.pod$/, readdir $dfh);
        closedir $dfh;
        @pods;
    };

    $self->{perlpods} = \@perldocs;
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

App::pacoon -

=head1 SYNOPSIS

  use App::pacoon;

=head1 DESCRIPTION

App::pacoon is

=head1 AUTHOR

Syohei YOSHIDA E<lt>syohex@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2012- Syohei YOSHIDA

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
