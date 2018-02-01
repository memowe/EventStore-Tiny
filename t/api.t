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
        return $state;
    });

    # store an event
    is $est->events->length => 0, 'No events';
    $est->store_event(AnswerGiven => {answer => 42});
    is $est->events->length => 1, 'One event after addition';

    # test if it's the right event
    is $est->events->apply_to->get('answer') => 42, 'Correct event added';
};

done_testing;
