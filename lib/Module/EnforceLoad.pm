package Module::EnforceLoad;
use strict;
use warnings;
use Carp qw/croak/;
use Sub::Util qw/prototype set_prototype/;

our %PRELOADS;
our %RELOADS;
our %OVERRIDE;
our $STATE;

sub import {
    my $class = shift;
    my ($arg) = @_ or return;

    if ($arg eq 'preload') {
        $STATE = $arg;
    }
    elsif ($arg eq 'start') {
        $STATE = $arg;
        %RELOADS = ();
        replace_subs($_) for keys %PRELOADS;
    }
    else {
        croak "Invalid arg: $arg";
    }
}

{
    no warnings 'redefine';
    no warnings 'once';

    my $nest = 0;
    *CORE::GLOBAL::require = sub {
        my $file = shift;

        $nest++;

        my $mod = $file;
        $mod =~ s{/}{::}g;
        $mod =~ s{.pm$}{};

        if ($STATE eq 'preload') {
            unless ($nest > 1 || $mod eq __PACKAGE__) {
                print "PRELOAD: $mod\n";
                $PRELOADS{$mod}++;
            }
        }
        else {
            print "RELOAD: $mod\n";
            $RELOADS{$mod}++;
        }

        my $ok = eval { CORE::require($file) };

        $nest--;

        die $@ unless $ok;

        $ok;
    };
}

sub replace_subs {
    my $mod = shift;

    return if $OVERRIDE{$mod}++;

    my $stash;
    {
        no strict 'refs';
        $stash = \%{"$mod\::"};
    }

    for my $i (keys %$stash) {
        my $orig = $mod->can($i) or next;
        next if $OVERRIDE{$orig};
        my $prototype = prototype($orig);

        my $new = sub {
            unless ($RELOADS{$mod}) {
                my ($pkg, $file, $line) = caller;
                die "Never loaded $mod, but trying to use $mod\::$i() at $file line $line.\n";
            }
            goto &$orig;
        };
        set_prototype($prototype, $new);

        no strict 'refs';
        no warnings 'redefine';
        *{"$mod\::$i"} = $new;
        $OVERRIDE{$new}++;
    }
}

1;
