package EventStore::Tiny::DataEvent;
use Mo qw(default);
extends 'EventStore::Tiny::Event';

has data => {};

sub new_from_template {
    my ($class, $event, $data) = @_;

    # "clone"
    return EventStore::Tiny::DataEvent->new(
        name            => $event->name,
        transformation  => $event->transformation,
        data            => $data,
        logger          => $event->logger,
    );
}

1;
__END__
