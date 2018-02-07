use strict;
use warnings;

use Test::More;

use_ok 'EventStore::Tiny::State';

subtest 'Simple constructor' => sub {
    my $state = EventStore::Tiny::State->new();
    is_deeply [$state->list] => [], 'State has no fields';
};

subtest 'Initialization' => sub {
    my $state = EventStore::Tiny::State->new(init => {answer => 42});
    is_deeply [$state->list] => ['answer'], 'State has the answer field only';
};

subtest 'Access' => sub {

    # init
    my $state = EventStore::Tiny::State->new(init => {answer => 42});
    is $state->get('answer') => 42, 'Correct answer field value';

    # modification
    $state->set(answer => 17);
    is $state->get('answer') => 17, 'Correct updated answer field value';

    # creation
    $state->set(foo => 'bar');
    is $state->get('foo') => 'bar', 'Correct new field value';

    # new modification
    $state->set(foo => 'baz');
    is $state->get('foo') => 'baz', 'Correct updated new field value';

    # overall content
    is_deeply [sort $state->list] => [sort qw(answer foo)], 'Correct fields';
};

done_testing;
