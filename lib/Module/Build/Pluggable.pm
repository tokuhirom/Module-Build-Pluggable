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
use Text::MicroTemplate qw/render_mt/;
use Data::Dumper;
use Module::Load;
use Module::Build::Pluggable::Util;

sub import {
    my $class = shift;
    my $pkg = caller(0);
    my $optlist = Data::OptList::mkopt(\@_);
    $OPTIONS = $optlist;
    my $code = join('',
        'use Class::Method::Modifiers qw/install_modifier/;',
        map { _mksrc(@$_) } @$optlist
    );
    $SUBCLASS = Module::Build->subclass(
        code => $code,
    );
}

sub _mksrc {
    my ($klass, $opts) = @_;
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Indent = 0;
    # XXX Do not install modifiers multiple times.
    # We need only one modifier. And complex data.
    return render_mt(<<'...', _mkpluginname($klass), Data::Dumper::Dumper($opts));
? my ($klass, $opts) = @_;
install_modifier(__PACKAGE__, 'around', 'resume', sub {
    my $orig = shift;
    my $builder = $orig->(@_);
    use <?= $klass ?>;
    my $plugin = <?= $klass ?>->new(builder => $builder, %{<?= $opts ?> || +{}});
    if ($plugin->can('HOOK_build')) {
        $plugin->HOOK_build();
    }
    return $builder;
});
...
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
        $module = _mkpluginname($module);
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
