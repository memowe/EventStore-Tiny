package EventStore::Tiny::ProgressMeter;

use strict;
use warnings;

use Class::Tiny {
    events_per_step     => undef,
    seconds_per_step    => undef,
    report_progress     => sub {die "report_progress is required\n"},
};

sub BUILD {
    my $self = shift;

    # Check non-lazy
    $self->report_progress;

    # Return nothing (will be ignored anyway)
    return;
}

1;

=pod

=encoding utf-8

=head1 NAME

EventStore::Tiny::ProgressMeter

=head1 REFERENCE

A class a progress meter should inherit to be called while events are processed. A typical use is to report the progress of the (possibly long-running) initial event application.

=head2 events_per_step

Defines the number of events inbetween progress meter calls. A value of 100 means that the progress meter is called every 100 event applications.

=head2 seconds_per_step

Defines the number of seconds inbetween progress meter calls. A value of 2 means that the progress meter is called every 2 seconds.

=head2 report_progress

    $progress_meter->report_progress(sub {
        my ($total, $current) = @_;
        say "Progress: $current / $total events";
    });

A subroutine reference (callback) which will be called to report application progress.

=head1 SEE ALSO

L<EventStore::Tiny>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018 Mirko Westermeier (mail: mirko@westermeier.de)

Released under the MIT License (see LICENSE.txt for details).

=cut
