package App::pacoon;
use strict;
use warnings;
use 5.008_001;

use Carp ();
use Config;
use Getopt::Long qw(:config posix_default no_ignore_case gnu_compat);
use Class::Inspector;
use ExtUtils::Installed;

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
    }, $class;
}

my %method_cache;

my %cmd_table = (
    modules => \&_output_modules,
    pod     => \&_output_pods,
    method  => \&_output_method,
);

sub _output_method {
    my $self = shift;

    for my $module (@_) {
        if (exists $method_cache{$module}) {
            print {$self->{out}} "$_\n" for @{$method_cache{$module}};
        } else {
            eval "require $module;";
            if ($@) {
                Carp::carp("Error: not found module '$module'");
                next;
            }

            my $methods = Class::Inspector->methods($module, 'public', 'full');
            $method_cache{$module} = $methods;

            print {$self->{out}} "$_\n" for @{$methods};
        }
    }
}

sub _output_modules {
    my $self = shift;
    print {$self->{out}} "$_\n" for @{$self->{modules}};
}

sub _output_pods {
    my $self = shift;
    print {$self->{out}} "$_\n" for (@{$self->{modules}}, @{$self->{perlpods}});
}

sub run {
    my $self = shift;

    $self->_init;

    while (my $line = <STDIN>) {
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
