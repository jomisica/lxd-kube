# lxd-projects-provisioning-kubernetes
Written by José Miguel Silva Caldeira <miguel@ncdc.pt>.

## Description:
This README explains how to create Kubernetes clusters inside LXD containers.

### Setting up a K8s Cluster using LXC/LXD 
> **Note:** These instructions are for development purposes and are not recommended for production use.

#### Installing LXC on Ubuntu

You can see more information on how to install and configure LXD at [this link](https://documentation.ubuntu.com/lxd/en/latest/installing/).

```shell
$ sudo snap install lxd
```

#### Configuring LXD

Before proceeding, you must create a bridge in Linux and specify the bridge you want LXD to use. We have created a bridge named "lxdbridge" for the provided examples.

If you need guidance on creating a bridge in Linux, you can refer to [this article](https://linuxhint.com/bridge-utils-ubuntu/) on bridge-utils in Ubuntu or any other resource of your choice.

To configure LXD, accept the default options, except for the bridge configuration. Do not accept the creation of the bridge by default. LXD will prompt you to specify a bridge to use, and you should provide the name of the bridge you created, which is "lxdbridge."

Having an external bridge can be useful for assigning a MAC address to each profile, ensuring that the containers maintain a consistent IP. Additionally, as Kubernetes relies on domain configuration, it's essential to ensure that the domain name you provide in the list of nodes resolves to the IP of each node.

If your DHCP server allows MAC reservations, create a reservation for each MAC address in the profile of each container. Make sure not to use MAC addresses associated with network devices in your network.

If your DNS allows you to create records, add one for each cluster using the domain of your choice. If not, configure your hosts file to map each domain to the IP address of each LXD instance.

### SSH KEYS

Inside the lxd/SSH-KEY directory, you will find an example PRIVATE and PUBLIC KEY. The public key will be distributed to all containers. This option is useful for using with Ansible or for direct SSH access for testing purposes.

You can create a new key pair and place it in the same location with the same name.

### List of projects

The following list of projects is provided for your reference, but you should modify it to meet your specific requirements. We will attempt to explain each column as clearly as possible, helping you understand your role in creating clusters.

| LXD_PROJECT    | LXD_PROFILE     | LXD_CONTAINER_NAME/HOSTNAME | LXC_CONTAINER_IMAGE | K8S_TYPE | K8S_API_ENDPOINT            | K8S_CLUSTER_NAME | K8S_POD_SUBNET | K8S_VERSION |
| --------------- | --------------- | ---------------------------- | ------------------- | -------- | ---------------------------- | ---------------- | -------------- | ----------- |
| project         | k8s-kmaster     | project-kmaster              | ubuntu:22.04        | master   | project-kmaster.ncdc.pt     | project          | 10.10.0.0/16  | 1.28.2      |
| project         | k8s-kworker1    | project-kworker1             | ubuntu:22.04        | worker   |                            |                  |              | 1.28.2      |
| project         | k8s-kworker2    | project-kworker2             | ubuntu:22.04        | worker   |                            |                  |              | 1.28.2      |
| project-dev     | k8s-dev-kmaster | project-dev-kmaster          | ubuntu:22.04        | master   | project-dev-kmaster.ncdc.pt | project-dev      | 10.11.0.0/16  | 1.28.2      |
| project-dev     | k8s-dev-kworker1| project-dev-kworker1         | ubuntu:22.04        | worker   |                            |                  |              | 1.28.2      |
| project-dev     | k8s-dev-kworker2| project-dev-kworker2         | ubuntu:22.04        | worker   |                            |                  |              | 1.28.2      |
| project-test    | k8s-test-kmaster| project-test-kmaster         | ubuntu:22.04        | master   | project-test-kmaster.ncdc.pt| project-test     | 10.12.0.0/16  | 1.28.2      |
| project-test    | k8s-test-kworker1| project-test-kworker1       | ubuntu:22.04        | worker   |                            |                  |              | 1.28.2      |
| project-test    | k8s-test-kworker2| project-test-kworker2       | ubuntu:22.04        | worker   |                            |                  |              | 1.28.2      |

The columns starting with LXD_ contain the data for configuring the containers, with the first four columns providing key details.

The columns starting with K8S_ contain Kubernetes configuration data, encompassing the remaining columns.

#### The LXD_PROJECT column

In LXD, we have the flexibility to create projects, similar to Kubernetes namespaces, which help segregate containers or virtual machines based on context. This enables better management of each Kubernetes cluster, ensuring all containers within a cluster reside in the same LXD project.

This column defines the project name, and it should be unique for each project.

#### The LXD_PROFILE column

LXD allows the creation of profiles, which can be used to define various aspects, including network options, storage, permissions, and more. You can assign a profile to a specific container, and any settings not specified in the custom profile will default to the settings in the default profile. This allows you to create profiles with only the options that differ from those in the default profile.

This column specifies the name of the profile file (without the extension) located within the lxd/profiles directory. Each container in the cluster should use a different profile.

#### The LXD_CONTAINER_NAME/HOSTNAME column

In LXD, containers must have unique names, even if they share the same name across different projects. This is because the hostname defaults to the container name, and having multiple containers with the same name will lead to network conflicts.

This column defines the name or hostname for each container.

#### The LXC_CONTAINER_IMAGE column

While LXD supports multiple system images for different purposes, the script provided here works with the APT package system and has been tested with images from ubuntu:18.04, ubuntu:20.04, and ubuntu:22.04.

This column specifies the image name and version for each container.

#### The K8S_TYPE column

This column is used by the script to determine whether to configure Kubernetes as a master or worker node.

This column can have two values: "master" or "worker."

#### The K8S_API_ENDPOINT column

This column defines the domain to use with the master plane. The domain should follow the format hostname.domain.xyz, where the hostname corresponds to the name specified in
the LXD_CONTAINER_NAME/HOSTNAME column.

This domain is used to access the Kubernetes API via a domain name rather than an IP address. The script will generate kubectl configurations for each cluster using the domain provided in this column.

Internally, Kubernetes relies on this domain in its cluster certificates.

The domain doesn't necessarily have to be a real, publicly accessible domain, but when resolving the domain to an IP address, it must point to the IP of the container that serves as the master node. However, it can be a real domain suitable for internet use.

#### The K8S_CLUSTER_NAME column

Given that you may have multiple clusters, each Kubernetes cluster should have a unique name. For instance, you might have a primary production cluster, another for application development, and yet another for testing applications or configuration updates. Differentiate these clusters by providing distinct names in this column.

This column specifies the name of each Kubernetes cluster.

#### The K8S_POD_SUBNET column

In Kubernetes, communication between pods and nodes relies on IP addresses. To avoid IP address conflicts in your clusters, each cluster should use a different network for its pod network.

This column specifies the network to be used in the cluster. It just needs to be specified in the master plans nodes.

#### The K8S_VERSION column

Kubernetes offers various versions for cluster deployment. The script uses the latest version defined in the configuration file. However, you have the flexibility to use older versions starting from at least version 1.22.0. This script has been tested with versions as old as 1.22.0, and it might support even older versions.

This column specifies the Kubernetes version to be used, ensuring consistency across all nodes within each cluster. However, you have the option to configure clusters with different versions.

### LXD Profiles

Each container in the cluster is assigned a profile. This is necessary so that we can specify a static MAC address for each container and specify the bridge that the container should belong to.

This way we also have more freedom to assign CPU and RAM resources to each container.

The "name" tag must contain the same file name without the extension, the same name specified in the node list.

```yaml
config:
  limits.cpu: "4"
  limits.memory: 4GB
  limits.memory.swap: "false"
  linux.kernel_modules: ip_tables,ip6_tables,nf_nat,overlay,br_netfilter
  raw.lxc: "lxc.apparmor.profile=unconfined\nlxc.cap.drop= \nlxc.cgroup.devices.allow=a\nlxc.mount.auto=proc:rw sys:rw\nlxc.mount.entry = /dev/kmsg dev/kmsg none defaults,bind,create=file"
  security.privileged: "true"
  security.nesting: "true"
description: LXD profile for Kubernetes
devices:
  eth0:
    hwaddr: 00:16:3e:00:c0:88
    name: eth0
    nictype: bridged
    parent: lxdbridge
    type: nic
  root:
    path: /
    pool: default
    type: disk
name: k8s-kmaster
used_by: []
```


### Clone the project

You can clone the repository to your preferred location.

```shell
$ git clone https://github.com/jomisica/lxd-projects-provisioning-kubernetes.git
```

Access the project directory

```shell
$ cd lxd-projects-provisioning-kubernetes
```


#### Create bridge

We provide a script to configure the bridge. But it should only be used on Ubuntu >=18.04. It has not been tested on other versions. You should also only use this script to create the bridge, if your computer only has one network interface. To configure it on computers with more than one network interface, it is possible but you have to modify the template we provide at lxc/netplan/netplancfg.yaml. It will also be necessary to edit the template if you need to configure a static IP on the bridge. If you need help on how to do this, get in touch.

Running the following command will create the 'lxdbridge' bridge and add the interface on your system that has the default route to the 'lxdbridge' bridge. This bridge will be configured with a dynamic IP, you must create a reserve with the bride's MAC Address in your DHCP, so that it maintains the same IP.

```shell
$ sudo bash create-lxd-bridge.sh
```

#### Install e configure LXD

We provide a script to install and configure LXD on Ubuntu 22.04, the only version we have tested. However, you should only install with the script if you just want simple options. Storage is in 'dir' mode by default, which will consume the same file system as other applications. The bridge configures the 'lxdbridge' as desired and must already be created. It is not in Cluster mode.
For more advanced configurations we must configure the 'lxc/preseed/preseed.yaml' template. If you need help on how to do this, get in touch.

```shell
$ sudo bash install-lxd.sh
```

#### Provision Kubernetes Clusters

The "cluster-config-data.csv" file defines the number of projects to be created and their properties. The data provided in this file creates three projects for LXD, with each project containing one master node and two worker nodes for Kubernetes.

You can and should adjust these settings to align with your specific requirements.

Inside the lxd/profiles directory, you will find a profile for each container used in your Kubernetes clusters. These profiles should be configured as needed. In the provided examples, a bridge named "lxdbridge" is used.

We plan to provide additional documentation on how to configure and use this script in the future.

```shell
$ bash lxd-kube provision
```

### Problem/BUGS report:

If you encounter any issues while running the script, please report them to help us make improvements.