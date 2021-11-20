# Routing

## Introduction

### VNet

Every VNet has one routing table. A VNet is identified by a 24 bit Virtual Network Identifier (VNI). A VNet can have multiple subnets.

### IPv4 vs. IPv6

Gardener on Metal's underlay network is an IPv6-only network. The overlay network supports IPv4/IPv6 dual stack.
In this document mostly IPv4 addresses are used for the overlay. If nothing different is mentioned, the same techniques apply also to IPv6!

Scenarios
---------
### Routing within a customer network

| Customer |     VM |   AZ |  Hypervisor | VNI | Private IPv4 |     Public IPv4 |
| -------- | ------ | ---- | ----------- | --- | ------------ | ---------------- |
|     A    | VM A.1 | FRA3 | SRV C5.FRA3 |  10 |  10.0.0.1/32 | 233.252.0.103/32 |
|     A    | VM A.2 | FRA3 | SRV C6.FRA3 |  10 |  10.0.0.2/32 |  203.0.113.12/32 |
|     A    | VM A.3 | FRA4 | SRV C2.FRA4 |  10 |  10.0.0.3/32 |  203.0.113.47/32 |

|  Hypervisor |   AZ |               IPv6 |
| ----------- | ---- | ------------------ |
| SRV C5.FRA3 | FRA3 | 2001:db8:f3:5::/64 |
| SRV C6.FRA3 | FRA3 | 2001:db8:f3:6::/64 |
| SRV C2.FRA4 | FRA4 | 2001:db8:f4:2::/64 |


`VM A.1` sends a ping request to `VM A.2`. This ping packet has an IPv4 header with `src IPv4: 10.0.0.1` and `dst IPv4: 10.0.0.2`.
The network hypervisor on `SRV C5.FRA3`, where `VM A.1` is running on, will encapsulate the packet. The encapsulation header will hold the following information: `dst IPv6: 2001:db8:f3:6::`, `VNI: 10`, `Protocol: 0x0800 (IPv4)`. In case of SRv6 encapsulation the VNI (10 = 0xa) would move into the dst IPv6 address: `SRv6 segment: 2001:db8:f3:6:a::`. The SRv6 segment address is provided via the routing control plane and MUST NOT be calculated by the packet's sender using the Host IP and VNI.

This is the simplest scenario of routing. To collect the information needed for encapsulating the packet, the hypervisor needs to receive all routes and all route updates of VNet 10. As soon as a new machine is joining VNet 10 or a machine gets terminated, route updates must be delivered to all hypervisors, that host VMs connected to VNet 10. This can be done via Kubernetes watches or, more performant, using a PubSub mechanism, that provides a queue per VNI. Route Updates will be published via this queue to all subscribers.
Using the route updates the hypervisor is able to create a routing table for VNet 10. The hypervisor will do longest prefix matching (LPM) for the target IP of the outgoing packet (here `10.0.0.2`) in the VM's respective VNI context.

When `VM A.1` sends a ping to `VM A.3` in a different AZ, the same happens again. The underlay networks of different AZs of the same region are routed - and also the routing information in the overlay networks is shared. The hypervisor would simply send the encapsulated packet to `SRV C2.FRA4`, which is located in FRA4 AZ.

Also, when a public IP is used as the destination IP, everything stays the same. Routing information of public endpoints, which reside in VNet 10, are distributed in the same way like private endpoints. When we look at IPv6, there are basically no "private" IP addresses anymore. Every IPv6 address is globally unique. But it is possible to not route them to the public internet - and by that make them "private".


### Unequal Cost Multi Path - UCMP

Two or more VMs may serve the same IP addresses. In this case there exist multiple routes for a given destination. Every route has a weight attached (0-255). According to the routes' weights outgoing flows will be assigned to the routes. E.g. if we have two routes to `10.0.0.2/32`, one with weight 100 and the other with weight 50, the first route will get assigned to `100/(100+50) = 2/3` of the new flows and the second route will be used for `50/(100+50) = 1/3` of the flows.


### Routing to the Internet

| Customer |     VM |   AZ |  Hypervisor | VNI | Private IPv4 |      Public IPv4 |
| -------- | ------ | ---- | ----------- | --- | ------------ | ---------------- |
|     A    | VM A.1 | FRA3 | SRV C5.FRA3 |  10 |  10.0.0.1/32 | 233.252.0.103/32 |

| Hypervisor  |   AZ |               IPv6 |
| ----------- | ---- | ------------------ |
| SRV C5.FRA3 | FRA3 | 2001:db8:f3:5::/64 |
| Router-1    | FRA3 |    2001:db8:1::/64 |
| Router-2    | FRA3 |    2001:db8:2::/64 |
| Router-3    | FRA4 |    2001:db8:3::/64 |
| Router-4    | FRA4 |    2001:db8:4::/64 |

`VM A.1` sends a ping request to `8.8.8.8` using its public IPv4 address `233.252.0.103`. The hypervisor does LPM for the target IP. As this IP address is outside of the Gardener on Metal installation, the longest prefix that can be found is the default route `0.0.0.0/0`. This route can be found within the `VNet 10` routing context, but it comes with a different target VNI: 1. The `VNI 1` is reserved for external internet traffic. All traffic, that is coming from a VM going to the public internet, will be encapsulated using VNI 1. In VNet 10's routing table two routes are installed to serve the default route. The first route is via Router-1 (`0.0.0.0/0 via 2001:db8:1:: VNI 1 - loc FRA3 - weight 100`) and the second via Router-2 (`0.0.0.0/0 via 2001:db8:2:: VNI 1 - loc FRA3 - weight 100`). Both routes will be used respective to their weights using UCMP. Router-3 and Router-4 are located in FRA4 AZ. This will also be indicated in the route: Router-3 announces `0.0.0.0/0 via 2001:db8:3:: VNI 1 - loc FRA4 - weight 100`). The client MUST prefer routes that align with their own `loc` parameter (here FRA3).

How will the VNet 10 routing table be filled with default routes from VNet 1? We do not distribute the information about the default routes via the VNI 10 queue. We would need to do this for every customer's VNet, which would require publishing route updates to multiple hundreds or thousands of queues (remember, every VNet has its own queue). Instead the route updates will be published via the VNI 1 queue only. The hypervisor is also always subscribed to the VNI 1 queue and imports the routes received via VNI 1 queue to the VNI 10 routing context. This way route updates of VNI 1 need only be sent to the queue once, but will be received by all hypervisors.

The router needs to know where to deliver the Ping response to. We do not want the router to subscribe to all VNI queues that exist. Therefore the route information about the public endpoints (here `233.252.0.103/32 via 2001:db8:f3:5:: VNI 10 - loc FRA3 - weight 100`) will also be published to the VNI 2 queue. The routing table of VNet 2 will contain all publicly accessible endpoints of all customers. The routers will import the routes of VNet 2 and by that know where to route incoming traffic.
Also the hypervisors may import the routes from VNet 2. This would allow communication via public endpoints between different customers. The downside is, this results in larger routing tables on every hypervisor. If this appears as not feasible, the hypervisors will not import VNet 2 routes, but only the default routes from VNet 1. Then all traffic will go to the routers and from there to the other customer.


### VNet Peering

VNet Peering describes the routing between two different virtual networks. We already learned the technical principles behind VNet Peering when we looked at Routing to the Internet: Importing of routes of a different VNet.

The use case here is the following: Customer A and customer B want to set up a private connection between their infrastructures. `VM A.1` should be able to ping `VM B.2` and vice versa. VNet Peering works by importing routes from the neighbor's VNet.

| Customer |     VM |   AZ |  Hypervisor | VNI |   Private IPv4 |
| -------- | ------ | ---- | ----------- | --- | -------------- |
|     A    | VM A.1 | FRA3 | SRV C5.FRA3 |  10 |    10.0.0.1/32 |
|     A    | VM A.3 | FRA3 | SRV C4.FRA3 |  10 |  172.16.0.3/32 |
|     B    | VM B.2 | FRA3 | SRV C6.FRA3 |  47 | 192.168.0.2/32 |
|     B    | VM B.3 | FRA3 | SRV C1.FRA3 |  47 |  172.16.0.3/32 |

|  Hypervisor |   AZ |               IPv6 |
| ----------- | ---- | ------------------ |
| SRV C1.FRA3 | FRA4 | 2001:db8:f3:1::/64 |
| SRV C4.FRA3 | FRA4 | 2001:db8:f3:4::/64 |
| SRV C5.FRA3 | FRA4 | 2001:db8:f3:5::/64 |
| SRV C6.FRA3 | FRA4 | 2001:db8:f3:6::/64 |

| Customer | VNI |         Subnet |
| -------- | --- | -------------- |
|     A    |  10 |     10.0.0.0/8 |
|     A    |  10 |  172.16.0.0/16 |
|     B    |  47 | 192.168.0.0/24 |
|     B    |  47 |  172.16.0.0/16 |

When establishing a peering connectivity between two VNets the customers can decide if they want to import all foreign routes or only routes with a specific prefix.

In this example we have two customers A (VNI 10) and B (VNI 47). Customer A is using the subnet `10.0.0.0/0` (VM A.1) and `172.16.0.0/16` (VM A.3). Customer B uses the subnets `192.168.0.0/24` (VM B.2) and `172.16.0.0/16` (VM B.3). As you can see we have partly overlapping IP spaces: `172.16.0.0/16` is used by both customers. As a result we cannot import the routes from VNet 47 (customer B) with the prefix `172.16.0.0/16` into the VNet 10 (customer A). Still, we can import VNet 47 routes with the prefix `192.168.0.0/24` to VNet 10. So in this case it is required to not import all routes of VNet 47 into VNet 10 but use a filter for `192.168.0.0/24`.

To also have a route from VNet 47 to VNet 10 we need to import the `10.0.0.0/8` prefixed routes from VNet 10 into VNet 47.

As a result the routing table of VNet 10 looks like this:

|    Destination | VNI |             via |  Loc | Weight | Remark                |
| -------------- | --- | --------------- | ---- | ------ | --------------------- |
|    10.0.0.1/32 |  10 | 2001:db8:f3:5:: | FRA3 |    100 |                       |
|  172.16.0.3/32 |  10 | 2001:db8:f3:4:: | FRA3 |    100 |                       |
| 192.168.0.2/32 |  47 | 2001:db8:f3:6:: | FRA3 |    100 | imported from VNet 47 |

And the routing table of VNet 47 looks like this:

|    Destination | VNI |             via |  Loc | Weight | Remark                |
| -------------- | --- | --------------- | ---- | ------ | --------------------- |
|    10.0.0.1/32 |  10 | 2001:db8:f3:5:: | FRA3 |    100 | imported from VNet 10 |
|  172.16.0.3/32 |  47 | 2001:db8:f3:1:: | FRA3 |    100 |                       |
| 192.168.0.2/32 |  47 | 2001:db8:f3:6:: | FRA3 |    100 |                       |

