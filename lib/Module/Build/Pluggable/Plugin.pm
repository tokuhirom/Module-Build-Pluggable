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

sub builder_class {
    my $self = shift;
    my $builder = $self->builder;
       $builder = ref $builder if ref $builder;
    return $builder;
}

# build
sub add_before_action_modifier {
    my ($self, $target, $code) = @_;
    my $builder = $self->builder_class;
    install_modifier($builder, 'before', "ACTION_$target", $code);
}

# build
sub add_action {
    my ($self, $name, $code) = @_;
    my $builder = $self->builder_class;
    no strict 'refs';
    *{"$builder\::ACTION_$name"} = $code;
}

# configure
sub build_requires {
    my $self = shift;
    Module::Build::Pluggable::Util->add_prereqs($self->builder, 'build_requires', @_);
}

# configure
sub configure_requires {
    my $self = shift;
    Module::Build::Pluggable::Util->add_prereqs($self->builder, 'configure_requires', @_);
}

1;

