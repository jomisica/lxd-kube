### Setting up K8s Cluster using LXC/LXD 
> **Note:** For development purpose and not recommended for Production use

#### Installing the LXC on Ubuntu 
```
$ sudo snap install lxd
```

#### Configuring LXD
We must create a bridge in Linux first and specify in LXD the bridge we want LXD to use. To be able to use the examples we created a bridge with the name "lxdbridge".


You can follow this article on how to create a bridge in Linux if you need or any other or several if you prefer.
https://linuxhint.com/bridge-utils-ubuntu/


To configure lxd we must accept the default options, except the bridge configuration. We must not accept the creation of the bridge by default and lxd will ask us if we want to specify a bridge to use, and we supply the bridge we created "lxdbridge".

Having an external bridge is useful, so we can add a MAC to each profile so that the containers always maintain the same IP.

Also, as Kubernetes is configured via domain, as in professional clouds, the domain name we provide in the list of machines must resolve to the IP of each machine.

#### Clone the project
You can clone the repository wherever you want.
```
$ git clone https://github.com/jomisica/lxd-projects-provisioning-kubernetes.git
```



#### Enter the project directory
```
$ cd lxd-projects-provisioning-kubernetes
```

#### Run the script
The cluster-config-data.csv file defines how many projects will be created and their properties. In the cluster-config-data.csv file there are three projects for LXD, in each project a master plane and two workers are created.

These settings can and should be changed to suit each person’s needs.

Within the lxd/profiles directory there is a profile for each of the containers that are used for kubernetes, these profiles must be configured accordingly. In this case I use a bridge named lxdbridge.

I will improve and comment on how to configure and use this script, but with time.
```
$ bash lxd-kube provision
```