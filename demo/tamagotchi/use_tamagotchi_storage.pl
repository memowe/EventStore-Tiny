#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Tamagotchi;

my $tama_sto = Tamagotchi->new;

my $anne    = $tama_sto->add_user('Anne');
my $bob     = $tama_sto->add_user('Bob');
my $charlie = $tama_sto->add_user('Charlie');

use Data::Dumper; print Dumper $tama_sto->data;
