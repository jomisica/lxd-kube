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


If your DHCP server allows you to create reservations, you must create a reservation for each MAC that is in the profile of each container. This MAC can be changed, however, you must not enter any MAC of any network device you use on your network.

If your DNS allows you to create records, you must add one for each cluster, with the domain you choose. If not, you must configure your hosts file to point each domain to the IP of each LXD instance.

#### SSH KEYS
Inside the lxd/SSH-KEY directory there is an example PRIVATE and PUBLIC KEY. The public key will be distributed across all containers. This option is useful for me to use with ansible or even directly via ssh to test.

You can create a new key pair and place it in the same location with the same name.

#### Clone the project
You can clone the repository wherever you want.
```
$ git clone https://github.com/jomisica/lxd-projects-provisioning-kubernetes.git
```

#### Enter the project directory
```
$ cd lxd-projects-provisioning-kubernetes
```

### List of projects
This list of projects is for my use, you should modify it to suit your needs, I will try to explain each column as best as possible. What is your role in creating clusters.

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


The columns starting with LXD_ contain the data for configuring the containers, the first four columns being.

The columns starting with K8S_ contain the data for the kubernetes configuration, the remaining columns are.

##### The LXD_PROJECT column
In LXD we can create projects, which separate containers or virtual machines for a given context, similar to Kubernetes namespaces. This way we can better manage each Kubernetes cluster. All containers in a given cluster are in an LXD project.

This column defines the name of the project. If we have more than one, we must give each project different names.

#### Run the script
The cluster-config-data.csv file defines how many projects will be created and their properties. In the cluster-config-data.csv file there are three projects for LXD, in each project a master plane and two workers are created.

These settings can and should be changed to suit each person’s needs.

Within the lxd/profiles directory there is a profile for each of the containers that are used for kubernetes, these profiles must be configured accordingly. In this case I use a bridge named lxdbridge.

I will improve and comment on how to configure and use this script, but with time.
```
$ bash lxd-kube provision
```