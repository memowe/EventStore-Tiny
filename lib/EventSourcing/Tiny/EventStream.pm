package EventSourcing::Tiny::EventStream;

use strict;
use warnings;
use Mo 'default';

has events => [];

sub add_event {
    my ($self, $event) = @_;

    # append event to internal list
    push @{$self->events}, $event;
}

sub length {
    my $self = shift;
    return scalar @{$self->events};
}

sub apply_to {
    my ($self, $state) = @_;

    # apply all events
    $state = $_->apply_to($state) for @{$self->events};

    # done
    return $state;
}

1;
__END__
