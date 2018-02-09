# EventStore::Tiny [![Build Status](https://travis-ci.org/memowe/EventStore-Tiny.svg?branch=master)](https://travis-ci.org/memowe/EventStore-Tiny)

A minimal event sourcing framework.

## Example

Prepare event types and their predefined state actions (by side-effect):

    use EventStore::Tiny;

    my $store = EventStore::Tiny->new;

    $store->register_event(UserAdded => sub {
        my ($state, $data) = @_;

        # Use $data to inject the new user into the given $state
        $state->{users}{$data->{id}} = {
            name => $data->{name},
        };
    });

Push an event to the event store. A high-resolution timestamp and an UUID will be generated automatically. Events execute their state actions on data they get here:

    $store->add_event(UserAdded => {id => 17, name => 'Bob'});

State is generated by replaying the stored events:

    say 'His name is ' . $store->data->{users}{17}; # Bob

See [Tamagotchi.pm][tpm] and [tamagotchi.t][tt] for a non-trivial demo.

[tpm]: t/9_demo/lib/Tamagotchi.pm
[tt]: t/9_demo/tamagotchi.t

## Features

- Flexible snapshots (high-resolution timestamps) and event substreams
- *TODO* Customizable event logging
- *TODO* Simple storage solution for events in the file system
- *TODO* Transparent snapshot caching mechanism to improve performance

## Author and license

Copyright (c) 2018 [Mirko Westermeier][mw] (mail: [mirko@westermeier.de][mail])

Details: [LICENSE.txt][license]

[mw]: http://mirko.westermeier.de
[mail]: mailto:mirko@westermeier.de
[license]: LICENSE.txt
