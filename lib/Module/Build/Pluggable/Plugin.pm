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

sub log_warn { shift->builder->log_warn(@_) }

# taken from  M::I::Can
# Check if we can run some command
use ExtUtils::MakeMaker;
sub can_run {
    my ($self, $cmd) = @_;

    my $_cmd = $cmd;
    return $_cmd if (-x $_cmd or $_cmd = MM->maybe_command($_cmd));

    for my $dir ((split /$Config::Config{path_sep}/, $ENV{PATH}), '.') {
        next if $dir eq '';
        require File::Spec;
        my $abs = File::Spec->catfile($dir, $cmd);
        return $abs if (-x $abs or $abs = MM->maybe_command($abs));
    }

    return;
}
1;

