package EventStore::Tiny::TransformationStore;

use strict;
use warnings;

use Class::Tiny {
    _transformation => sub {{}},
};

sub names {
    my $self = shift;
    return sort keys %{$self->_transformation};
}

sub get {
    my ($self, $name) = @_;
    return $self->_transformation->{$name};
}

sub set {
    my ($self, $name, $transformation) = @_;

    # Guard
    die "Event $name cannot be replaced!\n"
        if exists $self->_transformation->{$name};

    # Replace
    $self->_transformation->{$name} = $transformation;
}

1;
