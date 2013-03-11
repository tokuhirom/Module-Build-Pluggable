package Module::Build::Pluggable::GithubMeta;
use strict;
use warnings;
use utf8;
use parent qw(Module::Build::Pluggable::Base);
use Cwd ();

sub HOOK_configure {
    my ($self) = shift;

    return unless _under_git();
    return unless $self->can_run('git');

    my $remote = shift || 'origin';
    return unless my ($git_url) = `git remote show -n $remote` =~ /URL: (.*)$/m;
    return unless $git_url =~ /github\.com/;    # Not a Github repository

    my $http_url = $git_url;
    $git_url =~ s![\w\-]+\@([^:]+):!git://$1/!;
    $http_url =~ s![\w\-]+\@([^:]+):!https://$1/!;
    $http_url =~ s!\.git$!/tree!;

    $self->builder->meta_merge('resources', {
        'repository' => $git_url,
        'homepage'   => $http_url,
    });
    return 1;
}

sub _under_git {
    return 1 if -e '.git';
    my $cwd   = Cwd::getcwd;
    my $last  = $cwd;
    my $found = 0;
    while (1) {
        chdir '..' or last;
        my $current = Cwd::getcwd;
        last if $last eq $current;
        $last = $current;
        if ( -e '.git' ) {
            $found = 1;
            last;
        }
    }
    chdir $cwd;
    return $found;
}

1;

