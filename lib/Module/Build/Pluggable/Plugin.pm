package Module::Build::Pluggable::Plugin;
use strict;
use warnings;
use utf8;
use Class::Method::Modifiers qw/install_modifier/;
use Class::Accessor::Lite (
    ro => [qw/builder/]
);
use Module::Build::Pluggable::Util;

sub new {
    my $class = shift;
    my %args = @_;
    bless { %args }, $class;
}

sub add_before_action_modifier {
    my ($self, $target, $code) = @_;
    my $builder = $self->builder;
       $builder = ref $builder if ref $builder;
    install_modifier($builder, 'before', "ACTION_$target", $code);
}

sub build_requires {
    my $self = shift;
    Module::Build::Pluggable::Util->add_prereqs($self->builder, 'build_requires', @_);
}

sub configure_requires {
    my $self = shift;
    Module::Build::Pluggable::Util->add_prereqs($self->builder, 'configure_requires', @_);
}

1;

