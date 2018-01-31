use strict;
use warnings;

use Test::More;

use_ok 'EventSourcing::Tiny::Event';

subtest 'Default UUID' => sub {

    # init and check UUID
    my $ev = EventSourcing::Tiny::Event->new(name => 'foo');
    ok defined $ev->uuid, 'Event has an UUID';
    like $ev->uuid => qr/^(\w+-){4}\w+$/, 'UUID looks like an UUID string';

    # check another event's UUID
    my $ev2 = EventSourcing::Tiny::Event->new(name => 'foo');
    isnt $ev->uuid => $ev2->uuid, 'Two different UUIDs';
};

subtest 'Default high-resolution timestamp' => sub {

    # init and check timestamp
    my $ev = EventSourcing::Tiny::Event->new(name => 'foo');
    ok defined $ev->timestamp, 'Event has a timestamp';
    like $ev->timestamp => qr/^\d+\.\d+$/, 'Timestamp looks like a decimal';
    isnt $ev->timestamp => time, 'Timestamp is not the integer timestamp';

    # check another event's timestamp
    my $ev2 = EventSourcing::Tiny::Event->new(name => 'foo');
    isnt $ev->timestamp => $ev2->timestamp, 'Time has passed.';
};

subtest 'Construction arguments' => sub {

    # construct
    my $ev = EventSourcing::Tiny::Event->new(
        name            => 'foo',
        transformation  => sub {25 + shift},
    );

    # check
    is $ev->name => 'foo', 'Correct name';
    is $ev->transformation->(17) => 42, 'Correct transformation';
};

done_testing;
