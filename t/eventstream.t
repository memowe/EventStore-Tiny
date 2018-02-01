use strict;
use warnings;

use Test::More;

use List::Util qw(sum);
use EventSourcing::Tiny::State;
use EventSourcing::Tiny::Event;

use_ok 'EventSourcing::Tiny::EventStream';

my @test_numbers = (17, 25, 42);

# prepare events that add 17 or 25 or 42 to a state's "key" entry:
sub _test_events {
    return [map {
        my $add = $_;
        EventSourcing::Tiny::Event->new(name => 't', transformation => sub {
            $_[0]->set('key', ($_[0]->get('key') // 0) + $add);
            return $_[0];
        })
    } @test_numbers];
}

subtest 'Events at construction time' => sub {

    # construct event stream with an array of events
    my $es = EventSourcing::Tiny::EventStream->new(events => _test_events);
    is $es->length => scalar(@test_numbers), 'Right event count';

    # test event list members by applying
    for my $i (0 .. $#test_numbers) {
        my $s = EventSourcing::Tiny::State->new;
        is $es->events->[$i]->transformation->($s)->get('key')
            => $test_numbers[$i], "Correct transformation: $test_numbers[$i]";
    }
};

subtest 'Appending events' => sub {

    # construct an empty event stream
    my $es = EventSourcing::Tiny::EventStream->new;
    is $es->length => 0, 'Right event count';

    # add events
    $es->add_event($_) for @{+_test_events};
    is $es->length => scalar(@test_numbers), 'Right event count';

    # test event list members by applying
    for my $i (0 .. $#test_numbers) {
        my $s = EventSourcing::Tiny::State->new;
        is $es->events->[$i]->transformation->($s)->get('key')
            => $test_numbers[$i], "Correct transformation: $test_numbers[$i]";
    }
};

subtest 'Application' => sub {

    # construct event stream with an array of events
    my $es = EventSourcing::Tiny::EventStream->new(events => _test_events);

    subtest 'State given' => sub {

        # prepare a test state to be modified
        my $init_foo    = 666;
        my $state       = EventSourcing::Tiny::State->new;
        $state->set(key => $init_foo);

        # apply all events and check result
        $es->apply_to($state);
        is $state->get('key') => sum($init_foo, @test_numbers),
            'Correct chained application of all events';
    };

    subtest 'No state given' => sub {
        is $es->apply_to->get('key') => sum(@test_numbers),
            'Correct chained application of all events';
    };
};

done_testing;
