use strict;
use warnings;

use Test::More;

use EventSourcing::Tiny::State;

use_ok 'EventSourcing::Tiny::Event';
use_ok 'EventSourcing::Tiny::DataEvent';

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

subtest 'Application' => sub {

    subtest 'By return value' => sub {

        # event with return value application
        my $ev_trivial = EventSourcing::Tiny::Event->new(
            name            => 'foo',
            transformation  => sub {
                my $state = shift;
                $state->set(answer => 42);
                return $state;
            },
        );
        my $st = $ev_trivial->apply_to(EventSourcing::Tiny::State->new);
        is $st->get('answer') => 42, 'Correct result from event return value';
    };

    subtest 'By side effect' => sub {

        # create side-effect event
        my $ev = EventSourcing::Tiny::Event->new(
            name            => 'bar',
            transformation  => sub {
                my $state = shift;
                $state->set(quux => $state->get('quux') + 25);
                return 666; # return value makes no sense
            },
        );

        # prepare state for side effect application
        my $state = EventSourcing::Tiny::State->new;
        $state->set(quux => 17);

        # apply
        my $ret_st = $ev->apply_to($state);
        is $state->get('quux') => 42, 'Correct modified state';
    };

    subtest 'Conflicting application' => sub {

        # create event with different side-effect and return applications
        my $ev = EventSourcing::Tiny::Event->new(
            name            => 'baz',
            transformation  => sub {
                my $state = shift;
                $state->set(x => 17);
                return EventSourcing::Tiny::State->new(init => {x => 42});
            },
        );

        # prepare state to remember
        my $st      = EventSourcing::Tiny::State->new;
        my $ret_st  = $ev->apply_to($st);
        is $ret_st->get('x') => 42,
            'Return is more important than side-effect';
    };
};

subtest 'Data event' => sub {

    # construct data-driven event
    my $ev = EventSourcing::Tiny::DataEvent->new(
        name            => 'foo',
        transformation  => sub {
            my ($state, $data) = @_;
            $state->set($data->{key} => 42);
        },
        data            => {key => 'quux'},
    );

    # apply to empty state
    my $state = EventSourcing::Tiny::State->new;
    $ev->apply_to($state);
    is $state->get('quux') => 42, 'Correct state-update from data';
};

subtest 'Specialization' => sub {

    # construct data-driven event
    my $ev = EventSourcing::Tiny::Event->new(
        name            => 'foo',
        transformation  => sub {
            my ($state, $data) = @_;
            $state->set($data->{key} => 42);
        },
    );

    # specialize
    my $de = EventSourcing::Tiny::DataEvent->new_from_template(
        $ev, {key => 'quux'}
    );
    isa_ok $de => 'EventSourcing::Tiny::DataEvent';

    # apply to empty state
    my $state = EventSourcing::Tiny::State->new;
    $de->apply_to($state);
    is $state->get('quux') => 42, 'Correct state-update from new data';
};

done_testing;
