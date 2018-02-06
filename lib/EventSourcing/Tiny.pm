package EventSourcing::Tiny;
use Mo qw(default);

use EventSourcing::Tiny::Event;
use EventSourcing::Tiny::DataEvent;
use EventSourcing::Tiny::EventStream;
use EventSourcing::Tiny::Snapshot;

use Clone qw(clone);

our $VERSION = '0.01';

has registry    => {};
has events      => sub {EventSourcing::Tiny::EventStream->new};
has init_data   => {};

sub register_event {
    my ($self, $name, $transformation) = @_;

    $self->registry->{$name} = EventSourcing::Tiny::Event->new(
        name            => $name,
        transformation  => $transformation,
    );
}

sub event_names {
    my $self = shift;
    return [sort keys %{$self->registry}];
}

sub store_event {
    my ($self, $name, $data) = @_;

    # lookup template event
    my $template = $self->registry->{$name};
    die "Unknown event: $name!\n" unless defined $template;

    # specialize event with new data
    my $event = EventSourcing::Tiny::DataEvent->new_from_template(
        $template, $data
    );

    # done
    $self->events->add_event($event);
}

sub init_state {
    my $self = shift;

    # build new state from cloned init data
    return EventSourcing::Tiny::State->new(init => clone($self->init_data));
}

sub snapshot {
    my ($self, $timestamp) = @_;

    # no timestamp: last state
    return EventSourcing::Tiny::Snapshot->new(
        state       => $self->events->apply_to($self->init_state),
        timestamp   => $self->events->last_timestamp,
    ) unless defined $timestamp;

    # everything until the given timestamp
    my $events = $self->events->until($timestamp);
    return EventSourcing::Tiny::Snapshot->new(
        state       => $events->apply_to($self->init_state),
        timestamp   => $events->last_timestamp,
    );
}

1;
__END__
