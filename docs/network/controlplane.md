# Control Plane

## Requirements

* If a node loses connection, the routes must be removed from the system. A simple Kafka Queue does not do this. BGP removes all routes from the routing table, when a peer, that the routes were received from, disconnects.
