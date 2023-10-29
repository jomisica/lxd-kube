# lxd-projects-provisioning-kubernetes
Written by José Miguel Silva Caldeira <miguel@ncdc.pt>.

## Description:

This project is a collection of templates and scripts that aim to quickly and efficiently provision Kubernetes clusters on top of LXC containers.

By creating and/or configuring templates, it will be possible to optimize various aspects of both LXD and Kubernetes configurations.

The project already distributes templates and a configuration file that references them as well as the scripts used to create kubernetes containers and clusters.

This README explains how to create Kubernetes clusters inside LXD containers.

> **Note:** These instructions are for development purposes and are not recommended for production use.

> **Note:** It can be an initial configuration for production however many security and storage aspects have to be addressed in order to have minimal use in production.

> **Note:** At this moment, Kubernetes only uses container storage by default. In the future I will implement a way of passing templates to the CSI system, so that some type of storage is already configured from the beginning, and allows the use of various types.

## What is this project for?

This project is used to configure a Kubernetes cluster on top of LXC containers. However, there are at least two ways in which it is used: at a professional and non-professional level. Within these two main groups, there are many subgroups.

At a professional level, computers in production have a stable network, static IP addresses, do not change physical locations regularly, and more. They are dependent on other subsystems, such as storage and network infrastructure.

In a professional setting, system bridges are utilized to enable communication between the machines within the cluster and other subsystems. VLANs, tunnels, and other security measures may also be employed to facilitate separate communication for different project groups.

On the other hand, developers require, in addition to a stable cluster, an environment for their day-to-day work. They need a cluster with a specific configuration that can be deployed quickly and dismantled just as fast for testing purposes. These clusters are typically not stable at the infrastructure level since they often run on laptops that can be used in various locations, such as at a client's site, office, home, or café.

This script enables the creation of both types of situations: one for stable use based on a reliable network infrastructure, and another for developers who require flexibility during the development process. The Kubernetes cluster remains stable even if the development computer is restarted. Kubernetes, in essence, relies on consistent IP addresses from its installation.

In these cases, LXD does not function as a cluster but uses a bridge with NAT and leverages the developer's laptop as a gateway to the internet. The addresses assigned to the containers within the cluster are standardized, with the only variation being the IP address or network to which the computer is physically connected. The main concern is selecting a network that is not already in use in the locations frequented, to ensure it works seamlessly everywhere.

## The tree of files involved in the project

I will explain how script execution works and the relationship it has with templates and bootstrap scripts.

This is the file tree that is involved in this example project that comes with the project.


```shell
├── config
│   └── ncdc1.yaml
├── generated-configs
│   ├── kubernetes
│   │   └── templates
│   │       ├── ncdc1
│   │           ├── cni
│   │           │   ├── 000-install-calito-operator.yaml
│   │           │   └── 001-calito-custom resource.yaml
│   │           ├── init
│   │           │   └── kubeadm-init-config.yaml
│   │           └── join
│   │               └── kubeadm-join-config.yaml
│   └── lxc
│       ├── bridge
│       │   └── ncdc1
│       │   │   └── bridge.yaml
│       └── profiles
│           └── ncdc1
│               ├── k8s-kmaster.yaml
│               ├── k8s-kworker1.yaml
│               └── k8s-kworker2.yaml
├── kubernetes
│   ├── bootstrap
│   │   └── default
│   │       └── bootstrap.sh
│   ├── kubectl-configs
│   │   └── ncdc1
│   │       └── kubeconfig
│   └── templates
│       └── ncdc1
│           ├── cni
│           │   ├── 000-install-calito-operator.yaml
│           │   └── 001-calito-custom resource.yaml
│           ├── csi
│           ├── init
│           │   └── kubeadm-init-config.yaml
│           ├── join
│           │   └── kubeadm-join-config.yaml
│           └── kubeconfig
│               └── kubeadm-config.yaml
├── logs
│   └── ncdc1
│       ├── ncdc1-kmaster
│       │   ├── install.log
│       │   └── kubeadminit.log
│       ├── ncdc1-kworker1
│       │   ├── install.log
│       │   └── kubeadmjoin.log
│       └── ncdc1-kworker2
│           ├── install.log
│           └── kubeadmjoin.log
├── lxc
│   ├── lxdbridge
│   │   └── ncdc1
│   │      └── bridge.yaml
│   └── profiles
│       └── ncdc1
│           ├── k8s-kmaster.yaml
│           ├── k8s-kworker1.yaml
│           └── k8s-kworker2.yaml
└── lxd-kube
```

When starting the script with a specific configuration file, in this case 'test-local.csv,' the script begins by filtering the data, removing empty lines, trimming each line, and eliminating lines with the incorrect number of columns. It performs a basic check on the configuration file.

The script then iterates through the data rows. It starts by creating all the projects listed in the configuration file within LXD. These projects serve as containers, profiles, images, etc.

The script checks whether LXD is operating in a cluster. If not, it checks the existence of the file 'lxc/lxdbridge/< current project >/bridge.yaml.' If the file exists, it creates a local NAT bridge with the configurations from this file. If the file doesn't exist, no bridge is created. It's important that the bridge configurations align with the profiles, as demonstrated in the provided files for this test project. This configuration is ideal for laptops.

The script continues by creating all the profiles listed in the configuration file, naming each of them after the files located in 'lxc/profiles/< project name >/< profile name >.yaml.' If a file is missing, it defaults to the profile named 'k8s.yaml' available within 'lxc/profiles/default/'.

The script proceeds to create all the necessary containers for the project, associating each container with the corresponding profile created earlier.

It adds an SSH public key to each container, enabling access for analysis.

Once everything is set up in LXD projects, profiles, containers, the script waits for all containers to be running with active network interfaces and IP addresses before it can begin installing Kubernetes in the containers.

The script loops through the containers, starting with the first one, typically the Kubernetes master node. It checks whether the domain provided in the configuration file resolves to the container's IP address, assigned via DHCP or another method through the container profile during the creation process. If the domain resolves correctly, the installation proceeds; otherwise, it's aborted.

The script launches the bootstrap script located at 'kubernetes/bootstrap/< project name >/< container name hostname >/bootstrap.sh' if it exists. If not, it uses the default bootstrap script located at 'kubernetes/bootstrap/default/bootstrap.sh.' This script's role is to install dependencies and Kubernetes components, including containerd, but it can be customized for specific needs.

Next, the script generates configuration files to set up Kubernetes using data from the configuration file and the necessary generated tokens.

Base Kubernetes images are downloaded, depending on the cluster's version. This step can be time-consuming, taking up to half an hour on some occasions.

The master node is then initialized with the configuration files generated in previous steps. If everything goes smoothly, the master node is successfully initialized.

Subsequently, Flannel is installed in Kubernetes to manage the network and prepare for the addition of worker nodes.

That essentially concludes the installation of the master node.

The script then begins working on the worker nodes, which is a simpler and faster process.

It again checks for the existence of a custom bootstrap script in 'kubernetes/bootstrap/< project name >/< container name hostname >/bootstrap.sh,' falling back to the default script in 'kubernetes/bootstrap/default/bootstrap.sh' if needed. This script handles the software installation process.

Using the configuration file generated during the master node configuration, the script adds worker nodes to the cluster. This process is the same for all worker nodes.

When the script finishes adding all worker nodes, the configuration is complete, and the script concludes.

If an error occurs during any step of the process, the entire script is aborted, and an error message is displayed.


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

> **Note:** I had to change the format of the configuration files from CSV to YAML. This has to be done right at the beginning, now, as the configuration in a CSV file is possible but very limiting. As well as different from the configuration files of both LXD and Kubernetes, it is YAML that is most used.
The file format as YAML will make it easier to evolve this script with more options, so that it adapts throughout the development of LXD and Kubernetes.

### Example of configuration file

```yaml
config:
  description: This example project works on clustered LXD.
    But as it uses a NAT network interface, all containers must be in the same
    member of the LXD cluster, otherwise Kubernetes will not be able to
    communicate with the nodes. To do this, I use the target option to specify
    the LXD member that I need to create containers to be used by Kubernetes.
  lxd:
    projectName: ncdc1
    target: terra # cluster members: terra, marte
  kubernetes:
    clusterName: ncdc1
    version: 1.22.0
    podSubnet: 10.10.0.0/16
    controlPlaneEndpointDomain: ncdc.pt
  instances:
  - instance:
    lxd:
      name: ncdc1-kmaster
      image: ubuntu:22.04
      profile: k8s-kmaster
    kubernetes:
      type: master
  - instance:
    lxd:
      name: ncdc1-kworker1
      image: ubuntu:22.04
      profile: k8s-kworker1
    kubernetes:
      type: worker
  - instance:
    lxd:
      name: ncdc1-kworker2
      image: ubuntu:22.04
      profile: k8s-kworker2
    kubernetes:
      type: worker
```

## LXD Profiles

Each container in the cluster is assigned a profile. This is necessary so that we can specify a static MAC address for each container and specify the bridge that the container should belong to.

This way we also have more freedom to assign CPU and RAM resources to each container.

The "name" tag must contain the same file name without the extension, the same name specified in the node list.

```yaml
config:
  limits.memory: 2GB
  limits.cpu: 1,2
  #limits.cpu: "2"
  #limits.cpu: 0-3
  limits.cpu.allowance: 30%
  limits.cpu.priority: 5
  #limits.cpu.allowance: 50ms/200ms
  limits.memory.swap: "false"
  linux.kernel_modules: ip_tables,ip6_tables,nf_nat,overlay,br_netfilter
  raw.lxc: "lxc.apparmor.profile=unconfined\nlxc.cap.drop= \nlxc.cgroup.devices.allow=a\nlxc.mount.auto=proc:rw sys:rw\nlxc.mount.entry = /dev/kmsg dev/kmsg none defaults,bind,create=file"
  security.privileged: "true"
  security.nesting: "true"
description: LXD profile for Kubernetes
devices:
  eth0:
    name: eth0
    hwaddr: 00:16:3e:10:00:01
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

The 'config/project-config-file.yaml' file is the file used by the script to create the containers and configure the desired Kubernetes clusters. This same file is used when we want to destroy projects. It is a YAML file.

### Provision Kubernetes Clusters

To provision the projects that are defined in the configuration file, we run the following command:

```shell
$ bash lxd-kube provision --config project-config-file.yaml
```

### Destroy LXD projects and Kubernetes clusters

To destroy the projects that are defined in the configuration file, we run the following command:

```shell
$ bash lxd-kube destroy --config project-config-file.yaml
```


The actions are always carried out in bulk. For example, we can stop all LXD containers listed in the configuration file.
These actions become particularly important when working on multiple projects simultaneously. You might have several clusters configured, but you may only wish to work on one at a time. Pausing or stopping projects that are not in use at a given moment helps conserve resources.

### Stop containers

```shell
$ bash lxd-kube stop --config project-config-file.yaml
```

### Start containers

```shell
$ bash lxd-kube start --config project-config-file.yaml
```

### Pause containers

```shell
$ bash lxd-kube pause --config project-config-file.yaml
```

### Restart containers

```shell
$ bash lxd-kube restart --config project-config-file.yaml
```

## Suggestion for Improvements

If you identify opportunities for improvement in this project or encounter issues you'd like to report, your contribution is essential to make the project more robust and valuable. We actively encourage the user community to get involved and collaborate. Here are some ways to participate:

- **Report Issues**: If you come across any problems, bugs, or unexpected behavior while using this project, please report them on our [issues page](https://github.com/jomisica/lxd-projects-provisioning-kubernetes/issues). Make sure to provide detailed information so that we can understand and address the issue.

- **Make Suggestions**: If you have ideas for enhancing the project, adding features, or optimizing the user experience, feel free to share them on our [issues page](https://github.com/jomisica/lxd-projects-provisioning-kubernetes/issues). We'd love to hear your suggestions.

- **Contribute Code**: If you're a developer and want to contribute directly to the project, please consider creating pull requests (PRs).

Remember that your involvement is valuable and can help make this project even more useful to the community. Thank you for being a part of this open-source effort!