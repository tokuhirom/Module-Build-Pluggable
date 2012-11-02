package Module::Build::Pluggable;
use strict;
use warnings;
use 5.010001;
our $VERSION = '0.01';
use Module::Build;

our @MODULES;
our @ISA;
our $SUBCLASS;
our $OPTIONS;
use Data::OptList;
use Data::Dumper; # as serializer.
use Module::Load;
use Class::Method::Modifiers qw/install_modifier/;
use Module::Load ();
use Module::Build::Pluggable::Util;

sub import {
    my $class = shift;
    my $pkg = caller(0);
    return unless @_;

    my $optlist = Data::OptList::mkopt(\@_);
    $OPTIONS = [map { [ _mkpluginname($_->[0]), $_->[1] ] } @$optlist];

    _author_requires(map { $_->[0] } @$OPTIONS);

    $SUBCLASS = Module::Build->subclass(
        code => _mksrc(),
    );
}

sub _author_requires {
    my @devmods = @_;
    my @not_available;
    for my $mod (@devmods) {
        eval qq{require $mod} or push @not_available, $mod;
    }
    if (@not_available) {
        print qq{# The following modules are not available.\n};
        print qq{# `$^X $0 | cpanm` will install them:\n};
        print $_, "\n" for @not_available;
        print "\n";
        exit -1;
    }
}

sub _mksrc {
    my $data = do {
        local $Data::Dumper::Terse = 1;
        local $Data::Dumper::Indent = 0;
        Data::Dumper::Dumper($OPTIONS);
    };
    return sprintf(q{use Module::Build::Pluggable; Module::Build::Pluggable->run_build(__PACKAGE__, %s);}, $data);
}

sub run_build {
    my ($class, $builder_class, $options) = @_;
    install_modifier($builder_class, 'around', 'resume', sub {
        my $orig = shift;
        my $builder = $orig->(@_);
        for my $row (@{$options}) {
            my ($klass, $opts) = @$row;
            Module::Load::load($klass);
            my $plugin = $klass->new(builder => $builder, %{$opts || +{}});
            if ($plugin->can('HOOK_build')) {
                $plugin->HOOK_build();
            }
        }
        return $builder;
    });
}

sub _mkpluginname {
    my $module = shift;
    $module = $module =~ s/^\+// ? $module : "Module::Build::Pluggable::$module";
    $module;
}

sub new {
    my $class = shift;
    my $builder = $SUBCLASS->new(@_);
    my $self = bless { builder => $builder }, $class;
    $self->_init();
    return $self;
}

sub _init {
    my $self = shift;
    for my $opt (@$OPTIONS) {
        my ($module, $opts) = @$opt;
        $opts ||= +{};
        Module::Load::load($module);
        my $plugin = $module->new(builder => $self->{builder}, %$opts);
        for my $type (qw/configure_requires build_requires/) {
            Module::Build::Pluggable::Util->add_prereqs(
                $self->{builder},
                $type,
                $module, $module->VERSION,
            );
        }
        if ($plugin->can('HOOK_configure')) {
            $plugin->HOOK_configure();
        }
    }
}

sub DESTROY { }

our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;
    $AUTOLOAD =~ s/.*:://;
    return $self->{builder}->$AUTOLOAD(@_);
}

1;
__END__

=encoding utf8

=head1 NAME

Module::Build::Pluggable - ...

=head1 SYNOPSIS

  use Module::Build::Pluggable;

=head1 DESCRIPTION

Module::Build::Pluggable is

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF@ GMAIL COME<gt>

=head1 SEE ALSO

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
