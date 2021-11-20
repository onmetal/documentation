# DDoS Protection

When running commercial services on your infrastructure a good DDoS protection saves you a lot of money - or you spend a lot of money, as commercial DDoS protection solutions come at a high price.
We do not want to go into the cost details here. Instead we want to provide an overview over the different types of DDoS protection and how to implement them.

## Blackholing

The simplest type of DDoS protection is blackholing. It is specified in [RFC7999](https://datatracker.ietf.org/doc/html/rfc7999). Basically blackholing means shutting down single IP addresses. Traffic that usually gets transported to the service by an IP transit provider or via an internet exchange will be dropped.

E.g. you announce the IP range `192.0.2.0/24` and a service under the IP address `192.0.2.23` is being DDoSed. To protect your infrastructure you ask your IP transit provider to drop all traffic to the prefix `192.0.2.23/32`. This is done by announcing this prefix with the BGP community 666 to your IP transit provider. [Hurricane Electric](https://www.he.net/adm/blackhole.html) and [DE-CIX](https://www.de-cix.net/de/bibliothek/service-informationen/blackholing-guide) explain how to do blackholing on their websites.

As a result you will not get any packets to `192.0.2.23` anymore. This means this specific service is down - but the rest of your infrastructure still works.

Blackholing does not protect the attacked service! Instead it protects the rest of your infrastructure. It sacrifices the attacked service for the greater good.


## FlowSpec

FlowSpec is a bit more advanced to blackholing. In principle it works similar to blackholing: You ask your transit provider to drop traffic. But with FlowSpec you can implement a fine grained filter what traffic to drop. FlowSpec is described in [RFC5575](https://datatracker.ietf.org/doc/html/rfc5575).

With FlowSpec filter based on the following parameters:
1. Destination Prefix
2. Source Prefix
3. IP Protocol (matching the IP protocol byte field in the IP packet)
4. Port (matches source OR destination port)
5. Destination Port
6. Source Port (e.g. by filtering for source port 53 you can filter DNS amplification attacks)
7. ICMP type
8. ICMP code
9. TCP flags
10. Packet length
11. [DSCP](https://datatracker.ietf.org/doc/html/rfc2474) field
12. Fragment (don't fragment, is a fragment, first fragment, last fragment)

If you can identify the nature of the DDoS attack and you are able to match the attack with the options given by FlowSpec you can let your transit provider drop all requests of the attack. Ideally your service would stay online.
Obviously creating a pattern set, that matches all of the attack's packets is not very easy. So you may think about outsourcing DDoS protection to a scrubbing center - they have sophisticated machine learning models for that.

## Scrubbing Centers

You can pipe all your incoming traffic through a scrubbing center to clean it. The scrubbing center will announce your IP prefixes to the rest of the world using BGP. They will analyse the traffic based on layer 2-4 and try to clean it. The cleaned traffic will be sent to you - usually via a GRE tunnel or a PNI.

A scrubbing center is no replacement for an IP transit provider. They will only forward incoming traffic. For outgoing traffic you still need a transit provider.

There are usually two deployment models of scrubbing centers: *always-on* and *on-demand*. In the always-on case your traffic will always go through the scrubbing center (this is expensive). In the on-demand case you will only pipe your incoming traffic through the scrubbing center, when you are under attack (no illusions! this is also expensive!). Usually you pay scrubbing centers based on the provisioned bandwidth of *cleaned* traffic. Additionally there will be fees based on the number of prefixes and GRE tunnels or PNIs and for 24x7 support.

Here are a few scrubbing services in alphabetical order:

* [Akamai Prolexic](https://www.akamai.com/de/products/prolexic-solutions)
* [Arbor](https://www.netscout.com/arbor-ddos)
* [Cloudflare Magic Transit](https://www.cloudflare.com/magic-transit/)
* [Radware](https://www.radware.com/products/cloud-ddos-services/)

## Layer 7 Cloud Firewalls / CDNs

You can also let your application care about DDoS protection. Maybe they need a CDN anyways? Then a valid approach could also be to just say: *"Hey, all applications need to use a Cloud CDN or WAF. Every service that gets DDoSed will otherwise be blackholed!"* - If you are a small service provider this is probably the best strategy to get started. Implementing a Layer 7 CDN/WAF is quite easy and you do not have to talk to any sales person.

Layer 7 CDN / WAF combinations also come with a few other niceties. They do TLS offloading near the edge, accelerate static content delivery using caches or can detect and filter out SQL injections.

Be careful, Layer 7 services can be even more expensive than scrubbing centers - but usually the costs scale pretty nice with the services' workload!

Here are a few Layer 7 CDN/WAF services in alphabetical order:

* [Akamai CDN](https://www.akamai.com/solutions/content-delivery-network)
* AWS [Cloudfront](https://aws.amazon.com/cloudfront/), [Shield](https://aws.amazon.com/shield/), [WAF](https://aws.amazon.com/waf/)
* [Cloudflare](https://www.cloudflare.com)
* GCP [CDN](https://cloud.google.com/cdn), [Cloud Armor](https://cloud.google.com/armor)