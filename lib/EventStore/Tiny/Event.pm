package EventStore::Tiny::Event;
use Mo qw(default required build);

use UUID::Tiny qw(create_uuid_as_string);
use Time::HiRes qw(time);

has uuid            => sub {create_uuid_as_string};
has timestamp       => is => 'ro';
has name            => required => 1;
has transformation  => sub {sub {}};
has data            => {};

sub BUILD {
    my $self = shift;

    # make sure to set the timestamp non-lazy
    # see Mo issue #36 @ github
    $self->timestamp(time);
}

# lets transformation work on state and returns the result
sub apply_to {
    my ($self, $state) = @_;

    # check if application by side-effect or return value
    my $ret_val = $self->transformation->($state, $self->data);
    return $ret_val if $ret_val->isa('EventStore::Tiny::State');

    # returned something else: return original (modified) state
    return $state;
}

1;
__END__
