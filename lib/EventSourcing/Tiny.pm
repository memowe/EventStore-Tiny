package EventSourcing::Tiny;
use Mo qw(default);

use EventSourcing::Tiny::Event;
use EventSourcing::Tiny::DataEvent;
use EventSourcing::Tiny::EventStream;

our $VERSION = '0.01';

has registry    => {};
has events      => sub {EventSourcing::Tiny::EventStream->new};

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

1;
__END__
