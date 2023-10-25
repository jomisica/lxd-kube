# lxd-projects-provisioning-kubernetes
Written by José Miguel Silva Caldeira <miguel@ncdc.pt>.

## Description:

This project is a collection of templates and scripts that aim to quickly and efficiently provision Kubernetes clusters on top of LXC containers.

By creating and/or configuring templates, it will be possible to optimize various aspects of both LXD and Kubernetes configurations.

The project already distributes templates and a configuration file that references them as well as the scripts used to create kubernetes containers and clusters.

This README explains how to create Kubernetes clusters inside LXD containers.

> **Note:** These instructions are for development purposes and are not recommended for production use.

> **Note:** It can be an initial configuration for production however many security and storage aspects have to be addressed in order to have minimal use in production.

## What is this project for?

This project is used to configure a Kubernetes cluster on top of LXC containers. However, there are at least two ways in which it is used: at a professional and non-professional level. Within these two main groups, there are many subgroups.

At a professional level, computers in production have a stable network, static IP addresses, do not change physical locations regularly, and more. They are dependent on other subsystems, such as storage and network infrastructure.

In a professional setting, system bridges are utilized to enable communication between the machines within the cluster and other subsystems. VLANs, tunnels, and other security measures may also be employed to facilitate separate communication for different project groups.

On the other hand, developers require, in addition to a stable cluster, an environment for their day-to-day work. They need a cluster with a specific configuration that can be deployed quickly and dismantled just as fast for testing purposes. These clusters are typically not stable at the infrastructure level since they often run on laptops that can be used in various locations, such as at a client's site, office, home, or café.

This script enables the creation of both types of situations: one for stable use based on a reliable network infrastructure, and another for developers who require flexibility during the development process. The Kubernetes cluster remains stable even if the development computer is restarted. Kubernetes, in essence, relies on consistent IP addresses from its installation.

In these cases, LXD does not function as a cluster but uses a bridge with NAT and leverages the developer's laptop as a gateway to the internet. The addresses assigned to the containers within the cluster are standardized, with the only variation being the IP address or network to which the computer is physically connected. The main concern is selecting a network that is not already in use in the locations frequented, to ensure it works seamlessly everywhere.


## Installing LXD on Ubuntu

You can see more information on how to install and configure LXD at [this link](https://documentation.ubuntu.com/lxd/en/latest/installing/).

```shell
$ sudo snap install lxd
```

## Configuring LXD

Before proceeding, you must create a bridge in Linux and specify the bridge you want LXD to use. We have created a bridge named "lxdbridge" for the provided examples.

If you need guidance on creating a bridge in Linux, you can refer to [this article](https://linuxhint.com/bridge-utils-ubuntu/) on bridge-utils in Ubuntu or any other resource of your choice.

To configure LXD, accept the default options, except for the bridge configuration. Do not accept the creation of the bridge by default. LXD will prompt you to specify a bridge to use, and you should provide the name of the bridge you created, which is "lxdbridge."

Having an external bridge can be useful for assigning a MAC address to each profile, ensuring that the containers maintain a consistent IP. Additionally, as Kubernetes relies on domain configuration, it's essential to ensure that the domain name you provide in the list of nodes resolves to the IP of each node.

If your DHCP server allows MAC reservations, create a reservation for each MAC address in the profile of each container. Make sure not to use MAC addresses associated with network devices in your network.

If your DNS allows you to create records, add one for each cluster using the domain of your choice. If not, configure your hosts file to map each domain to the IP address of each LXD instance.

## SSH KEYS

Inside the lxd/SSH-KEY directory, you will find an example PRIVATE and PUBLIC KEY. The public key will be distributed to all containers. This option is useful for using with Ansible or for direct SSH access for testing purposes.

You can create a new key pair and place it in the same location with the same name.

## Configuration Files

The files describing Kubernetes containers and nodes are stored in the project's 'config' directory. Within this directory, there is a file named 'default.csv.' This file is used by the script as a list of LXC containers and Kubernetes nodes that can be created or destroyed.

The fundamental idea behind this project is to enable the configuration of multiple projects and facilitate the creation or removal of the projects or specific project lists as needed.

To achieve this, the script allows you to specify, via a parameter, which file to use. These files should be located in the 'config' folder. Here is where we create files that contain lists of the LXD containers and Kubernetes nodes we require. You can generate as many files as necessary for your projects. [See how to use](#verify-configuration-file)

These files use a CSV format and employ a comma as a separator. Every line should conclude with a comma, and each row should contain nine columns.

Below is an example of a file containing nine LXD containers, organized into three Kubernetes clusters, with three containers within each Kubernetes cluster.

| LXD_PROJECT    | LXD_PROFILE     | LXD_CONTAINER_NAME/HOSTNAME | LXC_CONTAINER_IMAGE | K8S_TYPE | K8S_API_ENDPOINT_DOMAIN            | K8S_CLUSTER_NAME | K8S_POD_SUBNET | K8S_VERSION |
| --------------- | --------------- | ---------------------------- | ------------------- | -------- | ---------------------------- | ---------------- | -------------- | ----------- |
| project         | k8s-kmaster     | project-kmaster              | ubuntu:22.04        | master   | project.pt     | project          | 10.10.0.0/16  | 1.28.2      |
| project         | k8s-kworker1    | project-kworker1             | ubuntu:22.04        | worker   |                            |                  |              | 1.28.2      |
| project         | k8s-kworker2    | project-kworker2             | ubuntu:22.04        | worker   |                            |                  |              | 1.28.2      |
| project-dev     | k8s-dev-kmaster | project-dev-kmaster          | ubuntu:22.04        | master   | project.pt | project-dev      | 10.11.0.0/16  | 1.28.2      |
| project-dev     | k8s-dev-kworker1| project-dev-kworker1         | ubuntu:22.04        | worker   |                            |                  |              | 1.28.2      |
| project-dev     | k8s-dev-kworker2| project-dev-kworker2         | ubuntu:22.04        | worker   |                            |                  |              | 1.28.2      |
| project-test    | k8s-test-kmaster| project-test-kmaster         | ubuntu:22.04        | master   | project.pt| project-test     | 10.12.0.0/16  | 1.28.2      |
| project-test    | k8s-test-kworker1| project-test-kworker1       | ubuntu:22.04        | worker   |                            |                  |              | 1.28.2      |
| project-test    | k8s-test-kworker2| project-test-kworker2       | ubuntu:22.04        | worker   |                            |                  |              | 1.28.2      |

The columns starting with LXD_ contain the data for configuring the containers, with the first four columns.

The columns starting with K8S_ contain Kubernetes configuration data, encompassing the remaining columns.

### The LXD_PROJECT column

In LXD, we have the flexibility to create projects, similar to Kubernetes namespaces, which help segregate containers or virtual machines based on context. This enables better management of each Kubernetes cluster, ensuring all containers within a cluster reside in the same LXD project.

This column defines the project name, and it should be unique for each project.

### The LXD_PROFILE column

LXD allows the creation of profiles, which can be used to define various aspects, including network options, storage, permissions, and more. You can assign a profile to a specific container, and any settings not specified in the custom profile will default to the settings in the default profile. This allows you to create profiles with only the options that differ from those in the default profile.

This column specifies the name of the profile file (without the extension) located within the lxd/profiles directory. Each container in the cluster should use a different profile.

### The LXD_CONTAINER_NAME/HOSTNAME column

In LXD, containers must have unique names, even if they share the same name across different projects. This is because the hostname defaults to the container name, and having multiple containers with the same name will lead to network conflicts.

This column defines the name or hostname for each container.

### The LXC_CONTAINER_IMAGE column

While LXD supports multiple system images for different purposes, the script provided here works with the APT package system and has been tested with images from ubuntu:18.04, ubuntu:20.04, and ubuntu:22.04.

This column specifies the image name and version for each container.

### The K8S_TYPE column

This column is used by the script to determine whether to configure Kubernetes as a master or worker node.

This column can have two values: "master" or "worker."

### The K8S_API_ENDPOINT_DOMAIN column

This column defines the domain to use with the master plane. The domain must follow the format dominio.xyz.
This will be transformed to hostname.domain.xyz where the hostname matches the name specified in the LXD_CONTAINER_NAME/HOSTNAME column.

This domain is used to access the Kubernetes API via a domain name rather than an IP address. The script will generate kubectl configurations for each cluster using the domain provided in this column.

Internally, Kubernetes relies on this domain in its cluster certificates.

The domain doesn't necessarily have to be a real, publicly accessible domain, but when resolving the domain to an IP address, it must point to the IP of the container that serves as the master node. However, it can be a real domain suitable for internet use.

### The K8S_CLUSTER_NAME column

Given that you may have multiple clusters, each Kubernetes cluster should have a unique name. For instance, you might have a primary production cluster, another for application development, and yet another for testing applications or configuration updates. Differentiate these clusters by providing distinct names in this column.

This column specifies the name of each Kubernetes cluster.

### The K8S_POD_SUBNET column

In Kubernetes, communication between pods and nodes relies on IP addresses. To avoid IP address conflicts in your clusters, each cluster should use a different network for its pod network.

This column specifies the network to be used in the cluster. It just needs to be specified in the master plans nodes.

### The K8S_VERSION column

Kubernetes offers various versions for cluster deployment. The script uses the latest version defined in the configuration file. However, you have the flexibility to use older versions starting from at least version 1.22.0. This script has been tested with versions as old as 1.22.0, and it might support even older versions.

This column specifies the Kubernetes version to be used, ensuring consistency across all nodes within each cluster. However, you have the option to configure clusters with different versions.

## LXD Profiles

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


## Clone the project

You can clone the repository to your preferred location.

```shell
$ git clone https://github.com/jomisica/lxd-projects-provisioning-kubernetes.git
```

Access the project directory

```shell
$ cd lxd-projects-provisioning-kubernetes
```


### Create bridge

We provide a script to configure the bridge. But it should only be used on Ubuntu >=18.04. It has not been tested on other versions. You should also only use this script to create the bridge, if your computer only has one network interface. To configure it on computers with more than one network interface, it is possible but you have to modify the template we provide at lxc/netplan/netplancfg.yaml. It will also be necessary to edit the template if you need to configure a static IP on the bridge. If you need help on how to do this, get in touch.

> **Note:** When testing on a virtual machine (e.g. virtualbox), it is possible, however the network interface in the vitualizer settings must allow the interface to be in promiscuous mode.

Running the following command will create the 'lxdbridge' bridge and add the interface on your system that has the default route to the 'lxdbridge' bridge. This bridge will be configured with a dynamic IP, you must create a reserve with the bride's MAC Address in your DHCP, so that it maintains the same IP.

```shell
$ sudo bash create-lxd-bridge.sh
```

### Install e configure LXD

We provide a script to install and configure LXD on Ubuntu 22.04, the only version we have tested. However, you should only install with the script if you just want simple options. Storage is in 'dir' mode by default, which will consume the same file system as other applications. The bridge configures the 'lxdbridge' as desired and must already be created. It is not in Cluster mode.
For more advanced configurations we must configure the 'lxc/preseed/preseed.yaml' template. If you need help on how to do this, get in touch.

```shell
$ sudo bash install-lxd.sh
```

## How to use the script

The 'config/default.csv' file is the file used by the script to create the containers and configure the desired Kubernetes clusters. This same file is used when we want to destroy projects. It is a CSV file that uses a comma as a separator. All lines must end with a comma. Each row must have nine columns.

### Verify Configuration File

This command will read the configuration file and filter only the lines that do not appear to have an error, you must check that no lines were excluded. If they were, it's because something was wrongly written in the file.

Check the default configuration file.
```shell
$ bash lxd-kube verifyconfig
```

Check a different configuration file.
```shell
$ bash lxd-kube verifyconfig --config k8s-1.22.0.csv
```

### Provision Kubernetes Clusters

To provision the projects that are defined in the 'default.csv' configuration file, we run the following command:

Using the default configuration file.
```shell
$ bash lxd-kube provision
```

Using different configuration file.
```shell
$ bash lxd-kube provision  --config k8s-1.22.0.csv
```

### Destroy LXD containers and Kubernetes clusters

To destroy the projects that are defined in the 'default.csv' configuration file, we run the following command:

Using the default configuration file.
```shell
$ bash lxd-kube destroyprojects
```

Using different configuration file.
```shell
$ bash lxd-kube destroyprojects --config k8s-1.22.0.csv
```


The actions are always carried out in bulk. For example, we can stop all LXD containers listed in the configuration file. It is essential to separate projects into different configuration files. However, if a file contains more than one project, the actions are consistently applied to all containers listed in the file.

Estas ações são importantes se trabalharmos com mais de um projecto ao mesmo tempo. Podemos ter configurados varios clusters, no entanto podemos querer trabalhar em apenas um de cada vez. Pausando ou parando os projectos que não estamos a usar no momento é uma poupança de recursos.

### Stop containers

Using different configuration file.
```shell
$ bash lxd-kube stop --config k8s-1.22.0.csv
```

### Start containers

Using different configuration file.
```shell
$ bash lxd-kube start --config k8s-1.22.0.csv
```

### Pause containers

Using different configuration file.
```shell
$ bash lxd-kube pause --config k8s-1.22.0.csv
```

### Restart containers

Using different configuration file.
```shell
$ bash lxd-kube restart --config k8s-1.22.0.csv
```

## Suggestion for Improvements

If you identify opportunities for improvement in this project or encounter issues you'd like to report, your contribution is essential to make the project more robust and valuable. We actively encourage the user community to get involved and collaborate. Here are some ways to participate:

- **Report Issues**: If you come across any problems, bugs, or unexpected behavior while using this project, please report them on our [issues page](https://github.com/jomisica/lxd-projects-provisioning-kubernetes/issues). Make sure to provide detailed information so that we can understand and address the issue.

- **Make Suggestions**: If you have ideas for enhancing the project, adding features, or optimizing the user experience, feel free to share them on our [issues page](https://github.com/jomisica/lxd-projects-provisioning-kubernetes/issues). We'd love to hear your suggestions.

- **Contribute Code**: If you're a developer and want to contribute directly to the project, please consider creating pull requests (PRs).

Remember that your involvement is valuable and can help make this project even more useful to the community. Thank you for being a part of this open-source effort!