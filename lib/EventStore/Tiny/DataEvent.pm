package EventStore::Tiny::DataEvent;
use parent 'EventStore::Tiny::Event';

use strict;
use warnings;

use Class::Tiny {
    data => sub {{}},
};

sub new_from_template {
    my ($class, $event, $data) = @_;

    # "clone"
    return EventStore::Tiny::DataEvent->new(
        name            => $event->name,
        transformation  => $event->transformation,
        data            => $data,
    );
}

# lets transformation work on state by side-effect
sub apply_to {
    my ($self, $state, $logger) = @_;

    # apply the transformation by side effect
    $self->transformation->($state, $self->data);

    # log this event, if logger present
    $logger->($self) if defined $logger;

    # returned the same state just in case
    return $state;
}

1;

=pod

=encoding utf-8

=head1 NAME

EventStore::Tiny::DataEvent

=head1 REFERENCE

EventStore::Tiny::DataEvent extends EventStore::Tiny::Event and implements the following additional attributes and methods.

=head2 data

    my $ev = EventStore::Tiny::DataEvent->new(data => {id => 42});

Sets concrete data for this event which will be used during application.

=head2 new_from_template

    my $concrete = EventStore::Tiny::DataEvent->new_from_template(
        $event, {id => 17}
    );

Creates a new data event based on an event (usually representing an event type which was registered before using L<EventStore::Tiny/register_event>).

=head3 apply_to

    $event->apply_to(\%state, $logger);

Applies this event's L<transformation> to the given state (by side-effect) and its L</data>. If a C<$logger> as a subref is given, it is used to log this application.

=head1 SEE ALSO

L<EventStore::Tiny>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018 Mirko Westermeier (mail: mirko@westermeier.de)

Released under the MIT License (see LICENSE.txt for details).

=cut
