package EventSourcing::Tiny::EventStream;
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

    # start with empty state object by default
    $state = EventSourcing::Tiny::State->new unless defined $state;

    # apply all events
    $state = $_->apply_to($state) for @{$self->events};

    # done
    return $state;
}

sub substream {
    my ($self, $predicate) = @_;

    # default predicate: take everything
    $predicate = sub {1} unless defined $predicate;

    # filter events
    my @events = grep {$predicate->($_)} @{$self->events};

    # build new sub stream
    return EventSourcing::Tiny::EventStream->new(events => \@events);
}

sub until {
    my ($self, $timestamp) = @_;

    # all events until the given timestamp (including)
    return $self->substream(sub {$_->timestamp <= $timestamp});
}

sub after {
    my ($self, $timestamp) = @_;

    # all events after the given timestamp (excluding)
    return $self->substream(sub {$_->timestamp > $timestamp});
}

1;
__END__
