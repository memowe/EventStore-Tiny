#!/usr/bin/env perl
use Test::Perl::Critic;
use FindBin;

all_critic_ok("$FindBin::Bin/../../lib");

__END__
