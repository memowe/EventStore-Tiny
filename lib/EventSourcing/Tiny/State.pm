package EventSourcing::Tiny::State;
use Mo qw(default build);

has init    => {};
has _data   => {};

sub BUILD {
    my $self = shift;
    $self->_data($self->init);
}

sub get {
    my ($self, $field) = @_;

    # find field in data
    return $self->_data->{$field};
}

sub set {
    my ($self, $field, $value) = @_;

    # inject new value into data
    $self->_data->{$field} = $value;
}

sub list {
    my $self = shift;

    # fields in this state are first-level keys in the data hash
    return keys %{ $self->_data };
}

1;
__END__
