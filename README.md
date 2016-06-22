# NAME

Module::EnforceLoad - Make sure your modules load their deps in preload
environments.

# DESCRIPTION

Unit tests are good. Unit tests can also be slow. Unit tests run faster if you
preload all your modules and then fork for each test. This scenario will fail
to catch when you forget to load a dependancy as the preload will satisfy it.
This can lead to errors you find in production instead of tests.

This module helps with the problem in the last paragraph. You load this module
**FIRST** then load your preloads, then call `enforce()`. From that point on
the code will die if you use a sub defined in one of your preloads, unless
something uses `use` or `require` to try to load the module after you call
`enforce()`.

# SYNOPSIS

    package My::Preloader;
    use Module::EnforceLoad;

    # Preloads
    use Moose;
    use Scalar::Util;
    use Data::Dumper;

    enforce();

    do 'my_test.pl';

my\_test.pl

    # Will die, despite being preloaded
    # (we use eval to turn it into a warning for this example)
    eval { print Data::Dumper::Dumper('foo'); 1 } or warn $@;

    require Data::Dumper;

    # Now this will work fine.
    print Data::Dumper::Dumper('foo');

# SOURCE

The source code repository for Test2 can be found at
`http://github.com/exodist/Module-EnforceRequire`.

# MAINTAINERS

- Chad Granum <exodist@cpan.org>

# AUTHORS

- Chad Granum <exodist@cpan.org>

# COPYRIGHT

Copyright 2016 Chad Granum <exodist@cpan.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See `http://dev.perl.org/licenses/`
