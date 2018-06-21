use strict;
use warnings;

use FindBin;
use Test::Perl::Critic -profile => "$FindBin::Bin/../../perlcritic.rc";

all_critic_ok("$FindBin::Bin/../../lib");

__END__
