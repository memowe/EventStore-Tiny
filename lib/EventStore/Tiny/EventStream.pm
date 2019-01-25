package EventStore::Tiny::EventStream;

use strict;
use warnings;

use Class::Tiny {
    events => sub {[]},
};

sub add_event {
    my ($self, $event) = @_;

    # Append event to internal list
    push @{$self->events}, $event;

    # Done
    return $event;
}

sub size {
    my $self = shift;
    return scalar @{$self->events};
}

sub first_timestamp {
    my $self = shift;
    return unless @{$self->events};
    return $self->events->[0]->timestamp;
}

sub last_timestamp {
    my $self = shift;
    return unless @{$self->events};
    return $self->events->[$self->size - 1]->timestamp;
}

sub apply_to {
    my ($self, $state, $logger) = @_;

    # Start with empty state by default
    $state = {} unless defined $state;

    # Apply all events
    $_->apply_to($state, $logger) for @{$self->events};

    # Done
    return $state;
}

sub substream {
    my ($self, $selector) = @_;

    # Default selector: take everything
    $selector = sub {1} unless defined $selector;

    # Filter events
    my @filtered = grep {$selector->($_)} @{$self->events};

    # Build new sub stream
    return EventStore::Tiny::EventStream->new(events => \@filtered);
}

sub before {
    my ($self, $timestamp) = @_;

    # Shorthand: stream is empty
    return $self if $self->size == 0;

    # Shorthand: timestamp is earlier than our first timestamp
    return EventStore::Tiny::EventStream->new
        if $self->first_timestamp > $timestamp;

    # Shorthand: timestamp is our last timestamp
    return $self if $timestamp == $self->last_timestamp;

    # Go left until the condition is true, then it's true for all earlier events
    my $i = $#{$self->events};
    $i-- while $self->events->[$i]->timestamp > $timestamp;

    # Create a new sliced event stream
    my @before_events = @{$self->events}[0 .. $i];
    return EventStore::Tiny::EventStream->new(events => \@before_events);
}

sub after {
    my ($self, $timestamp) = @_;

    # Shorthand: stream is empty
    return $self if $self->size == 0;

    # Shorthand: timestamp is later or equal to our last timestamp
    return EventStore::Tiny::EventStream->new
        if $self->last_timestamp <= $timestamp;

    # Go right until the condition is true, then it's true for all later events
    my $i = 0;
    $i++ while $self->events->[$i]->timestamp <= $timestamp;

    # Create a new sliced event stream
    my @after_events = @{$self->events}[$i .. $#{$self->events}];
    return EventStore::Tiny::EventStream->new(events => \@after_events);
}

1;

=pod

=encoding utf-8

=head1 NAME

EventStore::Tiny::EventStream

=head1 REFERENCE

EventStore::Tiny::Stream implements the following attributes and methods.

=head2 events

    my $event17 = $stream->events->[16];

Internal list representation (arrayref) of all events of this stream.

=head2 add_event

    $stream->add_event($event);

Adds an event to the stream.

=head2 size

    my $event_count = $stream->size;

Returns the number of events in this stream.

=head2 first_timestamp

    my $start_ts = $stream->first_timestamp;

Returns the timestamp of the first event of this stream.

=head2 last_timestamp

    my $end_ts = $stream->last_timestamp;

Returns the timestamp of the last event of this stream.

=head2 apply_to

    my $state = $stream->apply_to(\%state);

Applies the whole stream (all events one after another) to a given state (by default an empty hash). The state is changed by side-effect but is also returned.

=head2 substream

    my $filtered = $stream->substream(sub {
        my $event = shift;
        return we_want($event);
    });

Creates a substream using a given filter. All events the given subref returns true for are selected for this substream.

=head2 before

    my $pre_stream = $stream->before($timestamp);

Returns a substream with all events before or at the same time of a given timestamp.

=head2 after

    my $post_stream = $stream->after($timestamp);

Returns a substream with all events after a given timestamp.

=head1 SEE ALSO

L<EventStore::Tiny>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018-2019 Mirko Westermeier (mail: mirko@westermeier.de)

Released under the MIT License (see LICENSE.txt for details).

=cut
