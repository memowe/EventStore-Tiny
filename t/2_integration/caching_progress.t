use strict;
use warnings;

use Test::More;

use EventStore::Tiny;
use_ok 'EventStore::Tiny::ProgressMeter';

subtest 'Report callback of ES::T::ProgressMeter' => sub {
    eval {EventStore::Tiny::ProgressMeter->new};
    like $@ => qr/report_progress is required/, 'report_progress is required';
};

subtest 'Progress by number of events' => sub {
    my $est = EventStore::Tiny->new(logger => undef);

    # Prepare meter (log)
    my $meter_log = '';
    $est->progress_meter(EventStore::Tiny::ProgressMeter->new(
        events_per_step => 2,
        report_progress => sub {
            my ($total, $current) = @_;
            $meter_log .= " $current/$total";
        },
    ));

    # Prepare events
    $est->register_event(EventProcessed => sub {shift->{count}++});
    $est->store_event('EventProcessed') for 1 .. 10;

    # Initialize
    $est->init_cache;

    # Check result
    is $est->snapshot->state->{count} => 10, 'Correct transformation';
    is $meter_log => ' 1/10 3/10 5/10 7/10 9/10', 'Correct meter log';
};

subtest 'Progress by number of seconds' => sub {
    my $est = EventStore::Tiny->new(logger => undef);

    # Prepare meter (log)
    my $meter_log = '';
    $est->progress_meter(EventStore::Tiny::ProgressMeter->new(
        seconds_per_step    => 1,
        report_progress     => sub {
            my ($total, $current) = @_;
            $meter_log .= " $current/$total";
        },
    ));

    # Prepare events
    $est->register_event(TimePassed => sub {
        my ($state, $data) = @_;
        sleep $data->{sleep};
        $state->{count}++;
    });
    $est->store_event(TimePassed => {sleep => 0}) for 1 .. 3;
    $est->store_event(TimePassed => {sleep => 1});
    $est->store_event(TimePassed => {sleep => 0}) for 1 .. 4;

    # Initialize
    $est->init_cache;

    # Check result
    is $est->snapshot->state->{count} => 8, 'Correct transformation';
    is $meter_log => ' 1/8 4/8', 'Correct meter log';
};

done_testing;
