package Module::EnforceLoad;
use strict;
use warnings;

our %PRELOADS;
our %RELOADS;

sub import {

}

*CORE::GLOBAL::require = sub {

};

1;
