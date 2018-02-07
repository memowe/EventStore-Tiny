package EventStore::Tiny;
use Mo qw(default);

use EventStore::Tiny::Event;
use EventStore::Tiny::DataEvent;
use EventStore::Tiny::EventStream;
use EventStore::Tiny::Snapshot;

use Clone qw(clone);

our $VERSION = '0.01';

has registry    => {};
has events      => sub {EventStore::Tiny::EventStream->new};
has init_data   => {};

sub register_event {
    my ($self, $name, $transformation) = @_;

    $self->registry->{$name} = EventStore::Tiny::Event->new(
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
    my $event = EventStore::Tiny::DataEvent->new_from_template(
        $template, $data
    );

    # done
    $self->events->add_event($event);
}

sub init_state {
    my $self = shift;

    # clone init data
    return clone($self->init_data);
}

sub snapshot {
    my ($self, $timestamp) = @_;

    # decide which event (sub) stream to work on
    my $es = $self->events;
    $es = $es->until($timestamp) if defined $timestamp;

    # done
    return EventStore::Tiny::Snapshot->new(
        state       => $es->apply_to($self->init_state),
        timestamp   => $es->last_timestamp,
    );
}

1;
__END__
