package Module::Build::Pluggable;
use strict;
use warnings;
use 5.010001;
our $VERSION = '0.01';
use Module::Build;

our $SUBCLASS;
our $OPTIONS;

use Data::OptList;
use Data::Dumper; # as serializer.
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
        ## no critic.
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
    return sprintf(q{
        use Module::Build::Pluggable;
        sub resume {
            my $class = shift;
            my $self = $class->SUPER::resume(@_);
            Module::Build::Pluggable->call_triggers_all('build', $self, %s);
            $self;
        }
    }, $data);
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
    $self->call_triggers_all('build', $builder, $OPTIONS);
    return $self;
}

sub _init {
    my $self = shift;
    # setup (build|configure) requires
    for my $opt (@$OPTIONS) {
        my ($module, $opts) = @$opt;
        for my $type (qw/configure_requires build_requires/) {
            Module::Build::Pluggable::Util->add_prereqs(
                $self->{builder},
                $type,
                $module, $module->VERSION,
            );
        }
    }
}

sub call_triggers_all {
    my ($class, $type, $builder, $options) =@_;
    for my $opt (@$options) {
        my ($module, $opts) = @$opt;
        $class->call_trigger($type, $builder, $module, $opts);
    }
}

sub call_trigger {
    my ($class, $type, $builder, $module, $opts) =@_;

    Module::Load::load($module);
    my $plugin = $module->new(builder => $builder, %{ $opts || +{} });
    my $method = "HOOK_$type";
    if ($plugin->can($method)) {
        $plugin->$method();
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
