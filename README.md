![Main CI](https://github.com/wyhaines/evita/actions/workflows/ci/badge.svg)

# evita

The vision for Evita is a chat bot framework, written in Crystal, that draws inspiration from work done on the Ruby Lita framework, while seeking to keep things as simple as possible.

The framework should implement a message bus that is the heart of it's operations.

All message handlers run in a separate fiber, with a connection to the message bus. Chat adapters likewise run in fibers, connected to the message bus.

When a chat message is received by the chat bot, that message is placed onto the message bus. All handlers which are interested in incoming messages will receive the message. Every handler is given an opportunity to bid on the handling of that chat message. All bids get sent back into the message bus, where they are routed to the bid engine.

The bid engine chooses which bid will be accepted after either all bids are in, or at least one is in, and a timout has been exceeded. The winning bid will get signaled on the message bug allowing only the winning handler to receive the notification to process the message.

The winning handler will process the message, and then return it to the message bus, for routing back to the adapter that it originated from.



## Installation

TODO: Write installation instructions here

## Usage

TODO: Write usage instructions here

## Development

TODO: Write development instructions here

## Contributing

1. Fork it (<https://github.com/your-github-user/evita/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Kirk Haines](https://github.com/your-github-user) - creator and maintainer
