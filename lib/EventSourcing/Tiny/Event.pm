package EventSourcing::Tiny::Event;
use Mo qw(default required);

use UUID::Tiny qw(create_uuid_as_string);
use Time::HiRes qw(time);

has uuid            => sub {create_uuid_as_string};
has timestamp       => sub {time};
has name            => required => 1;
has transformation  => sub {sub {}};
has data            => {};

# lets transformation work on state and returns the result
sub apply_to {
    my ($self, $state) = @_;
    return $self->transformation->($state, $self->data);
}

1;
__END__
