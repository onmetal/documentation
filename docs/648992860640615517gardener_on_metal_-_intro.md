# Gardener on Metal
## The Cloud Native IaaS

### Overview
Gardener on Metal (short: *onmetal*) is a Cloud Native IaaS provider for your Private Cloud - licensed under [Apache License v2.0](https://www.apache.org/licenses/LICENSE-2.0) and other open source licenses.
Gardener on Metal aims to be the best deployment target for Cloud Native Applications.
If your application runs with Kubernetes and you want to deploy it on your own hardware,
Gardener on Metal is your IaaS provider of choice!

We love Kubernetes! 
Every part of the phyiscal infrastructure is managed using Kubernetes: Servers, Switches, Routers, NICs. 
By using Kubernetes as the control plane for compute, network, storage and applications you can reduce the complexity of your technology stack significantly. 
If your SREs already know how to manage applications with Kubernetes they will quite fast get the hang of a Kubernetes managed cloud infrastructure.

Gardener on Metal provides different infrastructure components you already know from hyperscalers:
- Kubernetes Clusters ([Gardener](https://gardener.cloud/) managed)
- Bare Metal Machines
- Virtual Machines
- Block Storage ([Ceph](https://docs.ceph.com/en/latest/) based)
- Object Storage ([Ceph](https://docs.ceph.com/en/latest/) based, S3 compatible)
- Virtual Networks (including true IPv4/IPv6 Dual-Stack support)
- Load Balancers
- NAT Gateways
- ...

> Gardener on Metal is not a new Open Stack. 
The target of Gardener on Metal is not to virtualize or consolidate your existing on-prem infrastructure, 
but to be a slim deployment target for your cloud native workload. This allows us to use some short-cuts.
For example onmetal's virtual networks have no support for Layer 2 Ethernet broadcasts. Instead the networks are Layer 3 only. This means all traffic between the instances is routed. The infrastructure therefore does not need to manage IP to MAC address resolutions, caching and cache invalidation. There is no need to care about multiplying packets of broadcasts, which could lead to micro-congestions and noisy-neighbor issues anymore.

> Gardener on Metal does not support live migration of VMs. 
Instead a cloud native application follows the cloud native principle, that single service instances are not handled like pets but like cattle. This means that any part of a Cloud Native Application may be terminated without impact of service availability. Instead of live migration, Gardener on Metal sends SIGKILL signals to the application so it can be removed from the load balancer and re-deployed on a different node. This may not be quite that easy with applications that have a large memory footprint due to large caches - on the other hand those applications also have issues when being live migrated.

## CPU Architectures

Gardener on Metal is tested on Intel and AMD x86_64 processors. Due to its modular architecture Gardener on Metal should be easily portable to ARM64 (AArch64) or RISC-V processors. This is on our roadmap but we have not set a deadline, yet.

## Network

The whole network control plane is part of Gardener on Metal. 
All physical network switches are part of a Kubernetes infrastructure cluster. We use Kubernetes operators for configuring and monitoring the switches. 
The Switch OS is [SONiC](https://azure.github.io/SONiC/) - an open source network operating system initially developed by Microsoft. Nowadays a lot of different switch vendors contribute to SONiC.
For high speed and low latency network access Gardener on Metal leverages newest NIC technology.
With [DPDK](https://www.dpdk.org/) and [rte_flow](https://doc.dpdk.org/guides/prog_guide/rte_flow.html) we are able to make use of a NIC's hardware acceleration while staying very flexible thanks to userspace network programming. SmartNICs (aka DPUs) are used for bare metal deployments to isolate different customers.

## Storage

Most applications need state. Gardener on Metal provides state via Block Storage and an S3-compatible Object Storage. We have forked the Rook-Ceph-Operator and adapted it to fit our production requirements. Most modifications are about day-2 operations of Ceph clusters. The target is to automate as much as possible of Ceph operations. Storage is hard. We want to make easier and available for everyone.

Gardener on Metal in a first step does not adopt the hyperconverged infrastructure philosophy. We build clusters with dedicated compute and storage nodes. 
- This allows us to scale both parts independent from another. Also storage is not always the same. You may want to change the ratio of NVMe space to HDD space.
- This allows to optimize according to your workload. If you need more HDD space for your datalake or your backups, just add more servers with spinning disks. Gardener on Metal's Ceph operator cares about integrating the new storage nodes into the cluster.

## Compute

Compute comes in different flavors with Gardener on Metal: As a bare metal instance or as a virtual machine.

- A bare metal instance is also often called a *dedicated server* or *root server*. The customer has full access to the server's hardware. We use SmartNICs aka DPUs to isolate a physical server from other customers.
Using a DPU the bare metal instance can consume additional managed services like managed Firewall, NAT gateways or network block devices.

- A Virtual Machine is in the end also *just a Linux process*. 
We deploy virtual machines via Kubernetes to a set of servers that act as hypervisors.
The customer gets root access to the VM and can do whatever he wants with the VM.

Kubernetes comes as a Service with Gardener on Metal.
The customer does not need to care about bare metal or VM administrations when a Gardener managed Kubernetes cluster is used. Gardener will care about installing all required packages and Kubernetes artifacts. With the provided kubeconfig customers can connect to their Kubernetes clusters within minutes.
