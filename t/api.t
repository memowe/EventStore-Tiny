use strict;
use warnings;

use Test::More;

use EventSourcing::Tiny::State;

use_ok 'EventSourcing::Tiny';

subtest 'Registration' => sub {

    # no events registered at the beginning
    my $est = EventSourcing::Tiny->new;
    is_deeply $est->event_names => [], 'No events stored at the beginning';

    # register a simple event
    $est->register_event(AnswerGiven => sub {
        my ($state, $data) = @_;
        $state->set(answer => $data->{answer});
    });
    is_deeply $est->event_names => ['AnswerGiven'], 'Event name is known';
};

subtest 'Storing an event' => sub {

    # prepare
    my $est = EventSourcing::Tiny->new;
    $est->register_event(AnswerGiven => sub {
        my ($state, $data) = @_;
        $state->set(answer => $data->{answer});
    });

    # try to store unknown event
    eval {
        $est->store_event(UnknownEvent => {throw => 'exception plx'});
        fail 'No exception thrown';
    };
    like $@ => qr/Unknown event: UnknownEvent!/,
        'Correct exception for unknown event';

    # store an event
    is $est->events->length => 0, 'No events';
    $est->store_event(AnswerGiven => {answer => 42});
    is $est->events->length => 1, 'One event after addition';

    # test if it's the right event
    is $est->events->apply_to->get('answer') => 42, 'Correct event added';
};

subtest 'Snapshot' => sub {

    # register test events
    my $est = EventSourcing::Tiny->new;
    $est->register_event(TestEvent => sub {
        my ($state, $data) = @_;
        $state->set(foo => ($state->get('foo') // 0) + $data->{foo});
    });

    # insert test events
    $est->store_event(TestEvent => {foo => $_}) for qw(17 25 42);

    subtest 'Unspecified snapshot' => sub {
        my $sn = $est->snapshot;
        isa_ok $sn => 'EventSourcing::Tiny::Snapshot';
        is $sn->timestamp => $est->events->last_timestamp,
            'Correct snapshot timestamp';
        isa_ok $sn->state => 'EventSourcing::Tiny::State';
        is $sn->state->get('foo') => 84, 'Correct snapshot';
    };

    subtest 'Specified timestamp snapshot' => sub {
        my $sep_ts = $est->events->events->[1]->timestamp;
        my $sn = $est->snapshot($sep_ts);
        isa_ok $sn => 'EventSourcing::Tiny::Snapshot';
        is $sn->timestamp => $sep_ts, 'Correct snapshot timestamp';
        isa_ok $sn->state => 'EventSourcing::Tiny::State';
        is $sn->state->get('foo') => 42, 'Correct snapshot';
    };
};

done_testing;
