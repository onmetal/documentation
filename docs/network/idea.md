Gardener on Metal provides an infrastructure to run Cloud Native Applications. Multiple tenants should use this infrastructure in a secure way. They should not interfere with each others' workload. Noisy neighbor disturbances should be avoided as best as possible.

### IPv4 & IPv6
Most of enterprise applications that exist use IPv4 networking. But IPv4 addresses are getting scarce and some ISPs do not provide dedicated IPv4 addresses to their clients anymore. IPv6 is newer and the better internet protocol. Gardener on Metal customers should be able to chose if they want to run their cluster with an IPv4-only network, IPv4/IPv6 dual-stack or IPv6-only. The large Cloud Service Providers retro-fit their networks with IPv6 support. That's a tedious task and if you build an infrastructure with the pure focus on IPv4 migrating to IPv6 will be very difficult. With Gardener on Metal IPv6 is a first class citizen.

### Layer 3 unicast only
Modern applications use IP based communication. In the early days of networking there were also other protocols like IPX or AppleTalk. Thankfully those days are over. Still, we see some applications, that use features from the Ethernet layer, that most IP networks are based on. A typical use case is cache invalidation, that a Java application triggers via UDP broadcasts to its neighbors (see [Java Caching System](https://commons.apache.org/proper/commons-jcs/)). In datacenter networking and especially virtual networking so called [BUM traffic](https://en.wikipedia.org/wiki/Broadcast,_unknown-unicast_and_multicast_traffic) creates a lot of pain for the operator. Also modern queueing and pubsub solutions came up: ActiveMQ, RabbitMQ, Kafka, NATS. Distributing information using such queueing system is much more comfortable and reliable.

We think Ethernet based networking does not fit into the Cloud Native world! You should use IP-based protocols instead!

By removing Ethernet networks from Gardener on Metal we save lots of complexity in our infrastructure. All networking is IP based and every packet will be routed. All traffic coming from a VM or a bare metal machine will be routed by the hypervisor or a SmartNIC to the target. There is no Ethernet connectivity between two machines but an IP network. A VM has its hypervisor configured as a router:

    # ip route show
    default via 169.254.0.1 dev eno0 proto dhcp src 233.252.0.103 metric 1024
    169.254.0.1/32 dev eno0 proto dhcp scope link src 233.252.0.103 metric 1024

    # ip -6 route show
    default via fe80::1 dev eno0 proto dhcpv6 src 2001:db8::1 metric 256 pref medium
    fe80::/64 dev eno0 proto kernel metric 256 pref medium

We reduce complexity and also increase resiliency a lot by avoiding BUM traffic.

### IPv6 underlay
The Gardener on Metal underlay network uses IPv6-only. We have no need to support IPv4 in the underlay. All customer traffic is [encapsulated](encapsulation.md) in IPv6 and sent through our underlay network. IPv6 helps structuring the address space and uses globally unique addresses. No need to use the same IPv4 address space multiple times and trying to find unused address ranges.