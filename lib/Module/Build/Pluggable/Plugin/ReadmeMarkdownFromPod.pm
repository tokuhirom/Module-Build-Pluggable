package Module::Build::Pluggable::Plugin::ReadmeMarkdownFromPod;
use strict;
use warnings;
use utf8;
use parent qw/Module::Build::Pluggable::Plugin/;
use Class::Accessor::Lite (
    ro => [qw/filename clean/],
);

our $VERSION = '0.01';

sub HOOK_configure {
    my ($self) = @_;
    $self->build_requires('Pod::Markdown' => 0);
}

sub HOOK_build {
    my ($self) = @_;
    require Pod::Markdown;
    my $src = $self->filename || $self->builder->dist_version_from;
    unless ($src) {
        die "Missing filename for ReadmeMarkdownFromPod";
    }

    my $parser = Pod::Markdown->new();
    $parser->parse_from_file($src);
    open my $fh, '>', 'README.mkdn' or die "Cannot open README.mkdn: $!\n";
    print {$fh} $parser->as_markdown;
    close $fh;

    if ($self->clean) {
        $self->add_to_cleanup('README.mkdn');
    }
}

1;

