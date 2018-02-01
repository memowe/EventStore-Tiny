package EventSourcing::Tiny::DataEvent;
use Mo qw(default);
extends 'EventSourcing::Tiny::Event';

has data => {};

sub new_from_template {
    my ($class, $event, $data) = @_;

    # "clone"
    return EventSourcing::Tiny::DataEvent->new(
        name            => $event->name,
        transformation  => $event->transformation,
        data            => $data,
    );
}

1;
__END__
