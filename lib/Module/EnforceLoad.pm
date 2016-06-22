package Module::EnforceLoad;

my %LOAD_TREE;
my %RELOADS;

BEGIN {
    our $MOD;

    sub file_to_mod {
        my $mod = shift;
        $mod =~ s{/}{::}g;
        $mod =~ s{.pm$}{};
        return $mod;
    }

    *CORE::GLOBAL::require = sub {
        my $file = shift;
        return CORE::require($file) if $file =~ m/^[0-9\.]+$/;

        my $mod = file_to_mod($file);

        my @stack = ($mod);
        while (my $m = shift @stack) {
            $RELOADS{$m}++;
            push @stack => keys %{$LOAD_TREE{$m}};
        }
        $LOAD_TREE{$mod} = {};
        $LOAD_TREE{$MOD}->{$mod} = $LOAD_TREE{$mod} if $MOD;
        local $MOD = $mod;
        CORE::require($file);
    };
}

use strict;
use warnings;
use Sub::Util qw/prototype set_prototype/;
use List::Util qw/first/;

my @PATTERNS;
my %OVERRIDE;

sub import {
    my $class = shift;
    push @PATTERNS => @_;

    my $caller = caller;
    no strict 'refs';
    *{"$caller\::enforce"} = \&enforce;
}

sub debug {
    require Data::Dumper;
    print Data::Dumper::Dumper(\%LOAD_TREE);
}

sub enforce {
    %RELOADS = ();
    replace_subs($_) for keys %INC;
}

sub replace_subs {
    my $file = shift;
    my $mod = file_to_mod($file);
    return if $OVERRIDE{$mod}++;
    return unless first { $mod =~ $_ } @PATTERNS;

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
            unless ($RELOADS{$mod} || $mod eq __PACKAGE__) {
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
