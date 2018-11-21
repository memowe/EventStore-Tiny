use strict;
use warnings;

use Test::More;
use File::Temp qw(tempfile);

use EventStore::Tiny;
use EventStore::Tiny::DataEvent;
use EventStore::Tiny::TransformationStore;

# Prepare test "file handle"
package TestFileHandle;
use Class::Tiny {history => sub {[]}};
sub print {push @{shift->history}, shift}
sub length {scalar @{shift->history}}
1;
package main;

subtest 'Default logger' => sub {
    my $print_target = TestFileHandle->new;

    # Prepare logger
    use_ok 'EventStore::Tiny::Logger';
    my $logger = EventStore::Tiny::Logger->new(print_target => $print_target);

    # Log a dummy event type (shouldn't happen)
    subtest 'Dummy event type' => sub {

        $logger->log_event(EventStore::Tiny::Event->new(
            name        => 'TestEventTypeStored',
            trans_store => EventStore::Tiny::TransformationStore->new,
        ));
        is $print_target->length => 1, 'Correct event history size';
        my $log_str = $print_target->history->[0];
        is $log_str => "TestEventTypeStored: NO DATA\n",
            'Correct event type string representation logged';
    };

    # Log a dummy event
    subtest 'Dummy event' => sub {
        $logger->log_event(EventStore::Tiny::DataEvent->new(
            name        => 'TestEventStored',
            trans_store => EventStore::Tiny::TransformationStore->new,
            data        => {a => 17, b => 42},
        ));
        is $print_target->length => 2, 'Correct event history size';
        my $log_str = $print_target->history->[1];
        is $log_str => "TestEventStored: { a => 17, b => 42 }\n",
            'Correct event string representation logged';
    };

    subtest 'Callback generation' => sub {

        subtest 'Method call' => sub {

            # Generate
            my $log_cb = $logger->log_cb;
            is ref($log_cb) => 'CODE', 'Subroutine reference generated';

            # Log a dummy event
            $log_cb->(EventStore::Tiny::DataEvent->new(
                name        => 'TestEventStored',
                trans_store => EventStore::Tiny::TransformationStore->new,
                data        => {foo => 1, bar => 2},
            ));

            # Test
            is $print_target->length => 3, 'Correct event history size';
            my $log_str = $print_target->history->[2];
            is $log_str => "TestEventStored: { bar => 2, foo => 1 }\n",
                'Correct event string representation logged';
        };

        subtest 'Package subroutine call' => sub {

            # Generate
            my $log_cb = EventStore::Tiny::Logger->log_cb(
                print_target => $print_target
            );

            # Log a dummy event
            $log_cb->(EventStore::Tiny::DataEvent->new(
                name        => 'TestEventStored',
                trans_store => EventStore::Tiny::TransformationStore->new,
                data        => {bar => 2, baz => 3},
            ));

            # Test
            is $print_target->length => 4, 'Correct event history size';
            my $log_str = $print_target->history->[3];
            is $log_str => "TestEventStored: { bar => 2, baz => 3 }\n",
                'Correct event string representation logged';
        };
    };

    subtest 'Default logging target STDOUT' => sub {

        # Redirect STDOUT
        my ($tmp_fh, $tmp_fn) = tempfile;
        select $tmp_fh;

        # Create without print target
        my $logger = EventStore::Tiny::Logger->new;

        # Log a dummy event
        $logger->log_event(EventStore::Tiny::DataEvent->new(
            name        => 'TestEventStored',
            trans_store => EventStore::Tiny::TransformationStore->new,
            data        => {baz => 17, quux => 42},
        ));

        # Restore STDOUT
        select STDOUT;
        close $tmp_fh;

        # Check results in temporary file
        open $tmp_fh, '<', $tmp_fn or die "Couldn't open $tmp_fn: $!\n";
        my $tmp = do {local $/; <$tmp_fh>};
        is $tmp => "TestEventStored: { baz => 17, quux => 42 }\n",
            'Correct event string representation logged to file';
    };
};

subtest 'Integration' => sub {
    my $print_target = TestFileHandle->new;

    subtest 'Direct event application logging' => sub {

        # Prepare logger
        my $logger = EventStore::Tiny::Logger->new(print_target => $print_target);

        subtest 'Event Type' => sub {

            # Prepare event
            my $ts = EventStore::Tiny::TransformationStore->new;
            $ts->set(Foo => sub {shift->{foo} = 42});
            my $event = EventStore::Tiny::Event->new(
                name        => 'Foo',
                trans_store => $ts,
            );

            subtest 'With logger set' => sub {
                my $state = {};
                $event->apply_to($state, $logger->log_cb);
                is_deeply $state => {foo => 42}, 'Correct state';
                is $print_target->length => 1, 'Correct history size';
                my $log_str = $print_target->history->[0];
                is $log_str => "Foo: NO DATA\n", 'Correct log string';
            };

            subtest 'Without logger' => sub {
                my $state = {};
                $event->apply_to($state);
                is_deeply $state => {foo => 42}, 'Correct state';
                is $print_target->length => 1, 'History unchanged';
            };
        };

        subtest 'Data Event' => sub {

            # Prepare
            my $ts = EventStore::Tiny::TransformationStore->new;
            $ts->set(Bar => sub {
                my ($state, $data) = @_;
                $state->{foo} = 17 + $data->{add};
            });
            my $event = EventStore::Tiny::DataEvent->new(
                name        => 'Bar',
                trans_store => $ts,
                data        => {add => 2},
            );

            subtest 'With logger set' => sub {
                my $state = {};
                $event->apply_to($state, $logger->log_cb);
                is_deeply $state => {foo => 19}, 'Correct state';
                is $print_target->length => 2, 'Correct history size';
                my $log_str = $print_target->history->[1];
                is $log_str => "Bar: { add => 2 }\n", 'Correct log string';
            };

            subtest 'Without logger' => sub {
                my $state = {};
                $event->apply_to($state);
                is_deeply $state => {foo => 19}, 'Correct state';
                is $print_target->length => 2, 'History unchanged';
            };

        };
    };

    # Prepare integration into event store
    $print_target = TestFileHandle->new;
    my $es = EventStore::Tiny->new(
        logger => EventStore::Tiny::Logger->log_cb(
            print_target => $print_target,
        ),
    );

    # Log and apply a dummy event
    $es->register_event(TestEventStored => sub {});
    $es->store_event(TestEventStored => {x => 'y', p => 'q'});
    $es->snapshot;

    # Test
    is $print_target->length => 1, 'Correct event history size';
    my $log_str = $print_target->history->[0];
    is $log_str => "TestEventStored: { p => \"q\", x => \"y\" }\n",
        'Correct event string representation logged';

    subtest 'Update logger' => sub {

        # Prepare new logger
        my $tmp_print_target = TestFileHandle->new;
        my $logger = EventStore::Tiny::Logger->log_cb(
            print_target => $tmp_print_target,
        );

        subtest 'Update' => sub {

            # Inject
            $es->logger($logger);

            # Add another event
            $es->store_event(TestEventStored => {x => 'q', p => 'y'});
            $es->snapshot;

            # Old logger unchanged
            is $print_target->length => 1, 'Correct old history size';
            my $log_str = $print_target->history->[0];
            is $log_str => "TestEventStored: { p => \"q\", x => \"y\" }\n",
                'Correct event string representation logged';

            # New logger changed
            is $tmp_print_target->length => 1, 'Correct new history size';
            my $tmp_log_str = $tmp_print_target->history->[0];
            is $tmp_log_str => "TestEventStored: { p => \"y\", x => \"q\" }\n",
                'Correct event string representation logged';
        };

        subtest 'Remove' => sub {

            # Remove
            $es->logger(undef);

            # Old logger unchanged
            is $print_target->length => 1, 'Correct old history size';
            my $log_str = $print_target->history->[0];
            is $log_str => "TestEventStored: { p => \"q\", x => \"y\" }\n",
                'Correct event string representation logged';

            # New logger changed
            is $tmp_print_target->length => 1, 'Correct new history size';
            my $tmp_log_str = $tmp_print_target->history->[0];
            is $tmp_log_str => "TestEventStored: { p => \"y\", x => \"q\" }\n",
                'Correct event string representation logged';
        };
    };
};

done_testing;
