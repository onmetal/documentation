# How to deploy ?

This document walks through how to deploy the virtualization stack on a baremetals using `virt-on-metal` as of now. Please note, this document only represents the current state and work is in progress yet.

## Prerequisites

- 4 baremetal machines with internal connectivity. While this document is tested for debian based hosts, it should be equally applicable for other linux-distributions with minor adaptations.
  - We'll refer them as compute-1, compute-2, compute-3 and compute-4.
  - One Baremetal will be a dedicated NAT Gateway machine, one as a kubernetes control-plane and two as a kubernetes nodes. VMs will only be deployed on the two kubernetes nodes.

## At a glance

- Virt-on-metal is a system to manage virtual machines at scale in a cloud-native fashion.
- It uses kubernetes premitives such as CRDS for VM management, libvirt as a base virtualization technology, MPLS tunnels for networking, and DHCP for IP assignment and iPXE boot.
- VMs are currently boot-up with PXE mechanism, and it plans to also support disk-based boot-up.

## Steps

### Install Kubernetes using kubeadm

- Disable swap and install kubeadm . This will be the kubernetes without kube-proxy using cilium plugin, which is capable of enabling network management in a more efficient way.

```bash
    Swapoff -a
    kubeadm init --skip-phases=addon/kube-proxy
```

- Once cluster is up and running, install cilium-plugin using helm.

```bash
    # Install Helm
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh

    # Install Cilium
    helm repo add cilium https://helm.cilium.io/
    helm --namespace kube-system install cilium cilium/cilium --version v1.10.2 --set cni.binPath=/usr/lib/cni

    cp usr/lib/cni/cilium-cni  /opt/cni/bin/cilium-cni # this depends on where kubelet looks for cni binary.
```

- Update Cilium CNI daemonset with following 2 changes.

```bash
At cilium-agent command, add following extra args: 
--mtu=1500
--k8s-api-server=https://<KUBE_APISERVER_IP>:6443
```

- Taint compute-4 as "func=NAT".

```bash
kubectl taint nodes compute-4 func=nat:NoSchedule
```

### Install libvirt daemon

- Install libvirt on compute-2, and compute-3. Compute-2 and Compute-3 will be the kubernetes nodes, where Virtual Machines will be spawned.

```bash
sudo apt install qemu-kvm libvirt-clients libvirt-daemon-system bridge-utils libguestfs-tools genisoimage virtinst libosinfo-bin
```

### Deploy VMlet controller

- Deploy the kubeconfig secret and daemonset in the kubernetes cluster.

```bash
kubectl apply -f https://github.com/onmetal/vmlet/blob/main/config/manager/kubecfg-secret.yaml  # Replace the kubeconfig with actual kubeconfig.
kubectl apply -f https://github.com/onmetal/vmlet/blob/main/config/manager/manager-ds.yaml

```

### Deploy NAT controller

The NAT controller is responsible of creating NAT on the server being tainted with "func=NAT". It is mainly responsable of using network namespace to create snat for VMs with the same virtual network ID. Additonally, it initialises MPLS tunnels with routers so that packets that are natted can be sent to routers.

```bash
kubectl apply -f https://github.com/onmetal/virtualisation-benchmark/blob/main/mpls-nat-operator.yaml

```

After executing the above command, a network namespace named nat-100, a VRF named vrf-100 will be created. Corresponding default and MPLS routing rules will be inserted automatically.

### Deploy DHCP Server

The configuration of private DHCP server is not automated. A dedicated VM needs to be spinned up to host the Kea DHCP server on the node serving as NAT. At this stage, it is reconmmended to use a prebuilt qcow2 image to avoid installation of kea and writing dhcp configuration files.
This VM has to be manually attached to VRF that was created in the previous step, and routing rule pointing to this VM has to be added. Assuming this VM uses the IP address, 10.1.1.2, and its tap has the name, tap111996580, the following commands shall be executed:

```bash
    ip link set tap111996580 master vrf-100 
    ip route add 10.1.1.2/32 dev tap111996580 vrf vrf-100
```

Inside this DHCP VM, assuming the prebuilt qcow2 is used to boot it up, the configuration file containing the subnet and VMs' IP address information has to be adapted. If the Kea docker image does not exist, the Dockerfile can be used to build a local image.

```bash
    docker build -t kea-dhcp4:1.9.8 --network=host  .
    docker run -v [-d] /root/kea-docker/kea-dhcp4-conf:/etc/kea --network host --name kea-dhcp4   kea-dhcp4:1.9.8
```

### Deploy VNet-controller

VNet-controller is deployed on each worker machine that hosts VMs. Its main task is to provide a configured TAP for VM, and corresponding routing rules. It is also responsable for starting isc-dhcp-relay to support iPXE booting.

```bash
k apply -f https://github.com/onmetal/virtualisation-benchmark/blob/main/mpls-tun-operator.yaml
```

### Deploy VM-scheduler

- Deploy vm-scheduler deployment.

```bash
k apply -f https://github.com/onmetal/vm-scheduler/blob/main/config/manager/manager.yaml
```

### Create First Virtual Machine

- Use following configuration to create the first virtual machine.
- @TODO Hardik Tao, this depends on how we configure the IP range in DHCP server etc.

```bash
kubectl apply -f https://github.com/onmetal/vmlet/blob/main/config/samples/vm7.yaml
```
