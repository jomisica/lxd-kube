## Description:

This document describes a way to physically and virtually connect the hosts belonging to an LXD cluster, and the containers that are used by the Kubernetes cluster. In this case there are only two physical hosts.

The following diagram describes the interconnection method.

![Network diagram](assets/cluster-example1.vpd.png)

As we can see in the diagram, each physical host only has one network interface in this example. Of course, the number of physical interfaces must be adjusted to the needs of each project.

Two virtual VLAN interfaces are created on each physical interface, one for each project in the example. These virtual interfaces will allow you to isolate the communication of each of the two LXD/kubernetes projects. All communications for a given project will be made on its VLAN.

A bridge is created on each host for each project, in this case BridgeP1 and BridgeP2. The project's VLAN virtual interface is added to each of these bridges. The bridge is used by LXD to configure the interface of each container to the project bridge.

Communications out of each project/VLAN must be routed in this case through the example router, which in this case must be the gateway for all VLANs and their networks. If a project needs to communicate with another project, it will do so as if it were communicating to the internet, except that the router detects that the desired network is directly connected to it and routes it between the projects' VLANs. If it is communications for the internet, the path will be taken through the router to reach the internet.

In Internet communications, in this case the router will have to deal with NAT to direct certain ports on the IP or public IPs to the VLAN network corresponding to each project.

The script to create each project to work in this way needs to know the bridge it should use, for this it must be defined in the profile of each container.
