package EventStore::Tiny;

use strict;
use warnings;
use Carp;

use EventStore::Tiny::Logger;
use EventStore::Tiny::Event;
use EventStore::Tiny::TransformationStore;
use EventStore::Tiny::EventStream;
use EventStore::Tiny::Snapshot;

use Clone qw(clone);
use IO::File;
use YAML::Syck;     # Exports Dump(), Load()
use Data::Compare;  # Exports Compare()

our $VERSION = '0.6';

use Class::Tiny {
    events          => sub {EventStore::Tiny::EventStream->new(
                             logger => shift->logger)},
    trans_store     => sub {EventStore::Tiny::TransformationStore->new},
    init_data       => sub {{}},
    logger          => sub {EventStore::Tiny::Logger->log_cb},
    slack           => 0, # Default: strict mode
    cache_distance  => 0, # Default: store snapshot each time. no caching: undef
}, '_cached_snapshot';

sub import_events {
    my ($self, $fn) = @_;

    # Rerieve
    my $file    = IO::File->new($fn, 'r');
    my $yaml    = do {local $/ = undef; <$file>};
    my $events  = Load $yaml;
    $file->close;

    # Create
    my $stream  = EventStore::Tiny::EventStream->new;
    for my $data (@$events) {
        $stream->add_event(EventStore::Tiny::Event->new(
            uuid        => $data->{uuid},
            timestamp   => $data->{timestamp},
            name        => $data->{name},
            trans_store => $self->trans_store,
            data        => $data->{data},
        ));
    }

    # Done
    $self->events($stream);
}

sub export_events {
    my ($self, $fn) = @_;

    # Simplify
    my @events = ();
    for my $event (@{$self->events->events}) {
        push @events, {
            uuid        => $event->uuid,
            timestamp   => $event->timestamp,
            name        => $event->name,
            data        => $event->data,
         };
    }

    # Export
    my $file = IO::File->new($fn, 'w');
    print $file Dump(\@events);
    $file->close;
}

sub register_event {
    my ($self, $name, $transformation) = @_;

    # Register transformation
    $self->trans_store->set($name => $transformation);
}

sub event_names {
    my $self = shift;
    return [$self->trans_store->names];
}

sub store_event {
    my ($self, $name, $data) = @_;

    # Lookup event type
    croak "Unknown event: $name!\n"
        unless defined $self->trans_store->get($name);

    # Create event
    my $event = EventStore::Tiny::Event->new(
        name        => $name,
        trans_store => $self->trans_store,
        data        => $data,
    );

    # Done
    return $self->events->add_event($event);
}

sub init_state {
    my $self = shift;

    # Clone init data
    return clone($self->init_data);
}

sub snapshot {
    my ($self, $timestamp) = @_;

    # Work on latest timestamp if not specified
    $timestamp //= $self->events->last_timestamp;
    my $es = $self->events->before($timestamp);

    # Check if the cached snapshot can be used
    my $state;
    my $cached_sn = $self->_cached_snapshot;
    if (defined $cached_sn and $cached_sn->timestamp <= $timestamp) {

        # Calculate what still needs to be applied
        $es = $es->after($cached_sn->timestamp);

        # Nothing? Great!
        return EventStore::Tiny::Snapshot->new(
            timestamp   => $self->_cached_snapshot->timestamp,
            state       => $self->slack ?
                $self->_cached_snapshot->state
                : clone($self->_cached_snapshot->state),
        ) if $es->size == 0;

        # Still something? Start here
        $state = $self->slack ? $cached_sn->state : clone $cached_sn->state;
    }

    # Calculate snapshot
    $state //= $self->init_state;
    my $snapshot = EventStore::Tiny::Snapshot->new(
        state       => $es->apply_to($state, $self->logger),
        timestamp   => $es->last_timestamp // 0,
    );

    # Caching disabled: done
    return $snapshot unless defined $self->cache_distance;

    # Cache snapshot if no cache present yet, but neccessary
    $self->_cached_snapshot($snapshot)
        if not defined $self->_cached_snapshot and $es->size > 0;

    # Cache snapshot if new event count > cache size
    $self->_cached_snapshot($snapshot)
        if @{$es->events} > $self->cache_distance;

    # Done
    return $snapshot;
}

sub is_correct_snapshot {
    my ($self, $snapshot) = @_;

    # Replay events before snapshot time
    my $our_sn = $self->snapshot($snapshot->timestamp);

    # True iff the generated state looks the same
    return Compare($snapshot->state, $our_sn->state);
}

1;

=pod

=encoding utf-8

=head1 NAME

EventStore::Tiny - A minimal event sourcing framework.

=begin html

<p>

<a href="https://badge.fury.io/pl/EventStore-Tiny">
    <img alt="CPAN version" src="https://badge.fury.io/pl/EventStore-Tiny.svg"></a>
<a href="https://travis-ci.org/memowe/EventStore-Tiny">
    <img alt="Travis CI tests" src="https://travis-ci.org/memowe/EventStore-Tiny.svg?branch=master"></a>
<a href="https://codecov.io/gh/memowe/EventStore-Tiny">
    <img alt="Codecov test coverage" src="https://codecov.io/gh/memowe/EventStore-Tiny/branch/master/graph/badge.svg"></a>
<a href="https://coveralls.io/github/memowe/EventStore-Tiny?branch=master">
    <img alt="Coveralls test coverage" src="https://coveralls.io/repos/github/memowe/EventStore-Tiny/badge.svg?branch=master"></a>

<br><br>

<a href="http://www.cpantesters.org/distro/E/EventStore-Tiny.html?distmat=1">
    <img alt="CPAN testers reports" src="https://img.shields.io/badge/testers-reports-blue.svg"></a>
<a href="http://matrix.cpantesters.org/?dist=EventStore-Tiny">
    <img alt="CPAN testers matrix" src="https://img.shields.io/badge/testers-matrix-blue.svg"></a>
<a href="https://github.com/memowe/EventStore-Tiny">
    <img alt="GitHub repository" src="https://img.shields.io/badge/github-code-blue.svg"></a>
<a href="https://github.com/memowe/EventStore-Tiny/issues">
    <img alt="GitHub issue tracker" src="https://img.shields.io/badge/github-issues-blue.svg"></a>

</p>

=end html

=head1 SYNOPSIS

    use EventStore::Tiny;

    my $store = EventStore::Tiny->new;

    # Register event type
    $store->register_event(UserAdded => sub {
        my ($state, $data) = @_;

        # Use $data to inject the new user into the given $state
        $state->{users}{$data->{id}} = {
            name => $data->{name},
        };
    });

    # ...

    # Store an event instance represented by type and data
    $store->store_event(UserAdded => {id => 17, name => 'Bob'});

    # ...

    # Work with the current state snapshot generated by event application
    say 'His name is ' . $store->snapshot->state->{users}{17}{name}; # Bob

=head1 DESCRIPTION

In Event Sourcing, the state of a system is calculated as the application of a stream of events representing each change of the system. This framework is a minimal approach to use these mechanics in simple perl systems and offers these features:

=over 2

=item *

Flexible snapshots (high-resolution timestamps) and event substreams.

=item *

Customizable event logging.

=item *

Simple storage solution for events in the file system.

=item *

Transparent snapshot caching mechanism to improve performance.

=back

The internal state of the system needs to be represented by a simple (nested) hash and all events need to operate on this hash only (by side-effect).

=head1 REFERENCE

EventStore::Tiny implements the following attributes and methods, grouped by topic.

=head2 CONSTRUCTION AND PERSISTENCE

=head3 new

    my $store = EventStore::Tiny->new(init_data => {answer = 42});

Standard constructor. Understands all attributes as arguments. For most use cases, these are the sensible arguments:

=over 4

=item init_data

A hashref representing the initial state. B<Default: C<{}>>

=item slack

See L</SLACK MODE> below. B<Default: 0>

=item cache_distance

The number of events after a new snapshot is cached for accellerated access. 0 means the cache is updated after each event. undef means the system does not use any caching. B<Default: 0>

=item logger

A subref (callback) which will be called each time an event is applied to the state. The callback gets this event as its only argument. B<Default: L<EventStore::Tiny::Logger/log_cb>>

=back

=head3 import_events

    $store->import_events($filename);

Loads events from a file which was written by L</export_events> before. It replaces an existing event stream in C<$store>. Note: before using the resulting events, the event types need to be registered as the transformations are only referenced.

=head3 export_events

    $store->export_events($filename);

Serializes the event stream to the file system. It can be imported back via L</import_events> later.

=head2 EVENT SOURCING WORKFLOW

=head3 register_event

    $store->register_event(ConnectionRemoved => sub {
        my ($state, $data) = @_;
        # Change $state depending on $data (by side-effect)
    });

Stores an event type in the system by name and action on the C<$state>. Events of this type can be added later to the event store by setting concrete C<$data> with L</store_event>.

=head3 store_event

    $store->store_event(ConnectionRemoved => {id => 42});

Stores a concrete instance of an event type in the event store. The instance is defined by its event type name and a hash of data used by the subref the event uses to manipulate the state.

=head3 snapshot

    my $state1    = $store->snapshot->state;

    my $snapshot  = $store->snapshot(1234217421);
    my $state2    = $snapshot->state;
    my $timestamp = $snapshot->timestamp; # 1234217421

Returns a L<EventStore::Tiny::Snapshot> object which basically consists of the corresponding state of the system (represented by a hashref) and the timestamp of the last used event. Snapshots are selected by the given argument timestamp, which returns the current snapshot at the given time. If no timestamp is given, the snapshot represents the last state of the system.

=head2 INTROSPECTION

=head3 event_names

    my $types = $store->event_names;

Returns an arrayref containing all event type names of registered events, sorted by name.

=head3 events

    my $event_stream = $store->events;

Returns the internal L<EventStore::Tiny::EventStream> object that stores all concrete events (L<EventStore::Tiny::Event> instances). Should be manipulated by L</store_event> only. Events should never be changed or removed.

=head3 trans_store

    my $transformation_store = $store->trans_store

Returns the internal L<EventStore::Tiny::TransformationStore> object that stores all transformation subroutines that events refer to. Should be manipulated by L</register_event> only. The transformation store should never be changed or removed.

=head3 init_state

    my $state = $store->init_state;

Returns a cloned copy of the initial state all events are applied on, which was defined by L</init_data> as a hashref.

=head2 SLACK MODE

By default, L<EventStore::Tiny> is in strict mode. That means, that all L</snapshot> data is cloned to prevent the internal state from illegal modification. However, if you B<really know what you're doing>, you can activate L</slack> mode to get references to the internal (cached) state. This improves performance a lot, but has also the downside that it can break your data consistence. You really have to make sure, that you modify your data with events only!

=head2 OTHER

=head3 is_correct_snapshot

    if ($store->is_correct_snapshot($snapshot)) {
        # ...
    }

Checks if a given L<EventStore::Tiny::Snapshot> instance is a valid snapshot of our L</events> event store. Mostly used for testing.

=head1 REPOSITORY AND ISSUE TRACKER

EventStore::Tiny's source repository is hosted on L<GitHub|https://github.com/memowe/EventStore-Tiny> together with an issue tracker.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018-2019 L<Mirko Westermeier|http://mirko.westermeier.de> (L<@memowe|https://github.com/memowe>, L<mirko@westermeier.de|mailto:mirko@westermeier.de>)

Released under the MIT License (see LICENSE.txt for details).

=head2 CONTRIBUTORS

=over 2

=item *

Mohammad S Anwar (L<@manwar|https://github.com/manwar>)

=item *

Toby Inkster (L<@tobyink|https://github.com/tobyink>)

=back

=cut
