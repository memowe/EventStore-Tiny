use strict;
use warnings;

use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";

use_ok 'Tamagotchi';

my $tama_sto = Tamagotchi->new;
isa_ok $tama_sto => 'Tamagotchi';

subtest 'User creation' => sub {

    # create users
    my $anne    = $tama_sto->add_user('Anne');
    my $bob     = $tama_sto->add_user('Bob');
    my $charlie = $tama_sto->add_user('Charlie');
    is $tama_sto->_event_store->events->length => 3, '3 events recorded';

    # check state after creation
    is_deeply $tama_sto->data => {
        users => {
            0 => {id => 0, name => 'Anne'},
            1 => {id => 1, name => 'Bob'},
            2 => {id => 2, name => 'Charlie'},
        },
    }, 'Correct state after user creation';
};

done_testing;
