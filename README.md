### Setting up K8s Cluster using LXC/LXD 
> **Note:** For development purpose and not recommended for Production use

#### Installing the LXC on Ubuntu 
```
$ sudo snap install lxd
```

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
```
$ bash lxd-kube provision
```