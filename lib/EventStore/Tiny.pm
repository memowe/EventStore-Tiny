package EventStore::Tiny;
use Mo qw(default);

use EventStore::Tiny::Logger;
use EventStore::Tiny::Event;
use EventStore::Tiny::DataEvent;
use EventStore::Tiny::EventStream;
use EventStore::Tiny::Snapshot;

use Clone qw(clone);
use Storable;

# enable handling of CODE refs (as event actions are code refs)
$Storable::Deparse  = 1;
$Storable::Eval     = 1;

our $VERSION = '0.01';

has registry    => {};
has events      => sub {EventStore::Tiny::EventStream->new(
                        logger => shift->logger)};
has init_data   => {};
has logger      => sub {EventStore::Tiny::Logger->log_cb};

# class method to construct
sub new_from_file {
    my (undef, $fn) = @_;
    return retrieve($fn);
}

{no warnings 'redefine';
sub store {
    my ($self, $fn) = @_;
    Storable::store($self, $fn);
}}

sub register_event {
    my ($self, $name, $transformation) = @_;

    $self->registry->{$name} = EventStore::Tiny::Event->new(
        name            => $name,
        transformation  => $transformation,
        logger          => $self->logger,
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

    # work on latest timestamp if not specified
    $timestamp //= $self->events->last_timestamp;
    my $es = $self->events->until($timestamp);

    # done
    return EventStore::Tiny::Snapshot->new(
        state       => $es->apply_to($self->init_state),
        timestamp   => $es->last_timestamp,
    );
}

1;
__END__
