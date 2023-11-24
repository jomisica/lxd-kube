set -o xtrace

env

# This script has been tested on Ubuntu 18.04, 20.04, 22.04
# For other versions of Ubuntu, you might need some tweaking

echo "Install essential packages"
#apt install -qq -y net-tools curl ssh software-properties-common 

if [ -d /mnt/apt/ ]; then
    cp /mnt/apt/* /var/cache/apt/archives/
fi

echo "Install containerd runtime"
apt update -qq
apt install -qq -y containerd apt-transport-https ca-certificates net-tools curl
echo return: $?

mkdir /etc/containerd >/dev/null
containerd config default > /etc/containerd/config.toml
sed -i 's/            SystemdCgroup = false/            SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

#curl -s https://packages.cloud.google.com/apt/dists/kubernetes-xenial/main/binary-amd64/Packages | grep Version | awk '{print $2}'
echo "Add apt repo for kubernetes"
curl -sS https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/kubernetes-apt-keyring.gpg
cat <<EOF | tee /etc/apt/sources.list.d/kubernetes.list
deb [signed-by=/etc/apt/trusted.gpg.d/kubernetes-apt-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main
EOF

apt update -qq

echo "Install Kubernetes components (kubeadm, kubelet and kubectl)"
apt install -qq -y kubeadm=${K8S_VERSION}-00 kubelet=${K8S_VERSION}-00 kubectl=${K8S_VERSION}-00
echo return: $?
apt-mark hold kubelet kubeadm kubectl

echo 'KUBELET_EXTRA_ARGS="--fail-swap-on=false"' > /etc/default/kubelet
systemctl restart kubelet

apt autoremove -y

cat <<EOF | tee /etc/crictl.yaml
runtime-endpoint: "unix:///run/containerd/containerd.sock"
timeout: 0
debug: false
EOF







# ctr image export flannel-cni-plugin-v1.2.0.tar docker.io/flannel/flannel-cni-plugin:v1.2.0
# ctr image export flannel-v0.22.3.tar docker.io/flannel/flannel:v0.22.3
# ctr image export coredns-v1.8.4.tar k8s.gcr.io/coredns/coredns:v1.8.4
# ctr image export etcd-3.5.0-0.tar k8s.gcr.io/etcd:3.5.0-0
# ctr image export kube-apiserver-v1.22.2.tar k8s.gcr.io/kube-apiserver:v1.22.2
# ctr image export kube-controller-manager-v1.22.2.tar k8s.gcr.io/kube-controller-manager:v1.22.2
# ctr image export kube-proxy-v1.22.2.tar k8s.gcr.io/kube-proxy:v1.22.2
# ctr image export kube-scheduler-v1.22.2.tar k8s.gcr.io/kube-scheduler:v1.22.2
# ctr image export pause-3.5.tar k8s.gcr.io/pause:3.5
# ctr image export kube-rbac-proxy-v0.15.0.tar quay.io/brancz/kube-rbac-proxy:v0.15.0
# ctr image export speaker-v0.13.11.tar quay.io/metallb/speaker:v0.13.11
# ctr image export node-exporter-v1.6.1.tar quay.io/prometheus/node-exporter:v1.6.1
# ctr image export harbor-adapter-trivy-2.9.1-debian-11-r0.tar  docker.io/bitnami/harbor-adapter-trivy:2.9.1-debian-11-r0
# ctr image export harbor-portal-2.9.1-debian-11-r0.tar  docker.io/bitnami/harbor-portal:2.9.1-debian-11-r0
# ctr image export mariadb-11.1.2-debian-11-r1.tar  docker.io/bitnami/mariadb:11.1.2-debian-11-r1
# ctr image export nginx-1.25.3-debian-11-r1.tar  docker.io/bitnami/nginx:1.25.3-debian-11-r1
# ctr image export postgresql-13.13.0-debian-11-r4.tar  docker.io/bitnami/postgresql:13.13.0-debian-11-r4
# ctr image export configmap-reload-v0.5.0.tar docker.io/jimmidyson/configmap-reload:v0.5.0
# ctr image export busybox-latest.tar  docker.io/library/busybox:latest
# ctr image export local-path-provisioner-v0.0.24.tar  docker.io/rancher/local-path-provisioner:v0.0.24
# ctr image export controller-v0.13.11.tar  quay.io/metallb/controller:v0.13.11
# ctr image export prometheus-config-reloader-v0.69.0.tar quay.io/prometheus-operator/prometheus-config-reloader:v0.69.0
# ctr image export prometheus-operator-v0.69.0.tar  quay.io/prometheus-operator/prometheus-operator:v0.69.0
# ctr image export alertmanager-v0.26.0.tar quay.io/prometheus/alertmanager:v0.26.0
# ctr image export blackbox-exporter-v0.24.0.tar  quay.io/prometheus/blackbox-exporter:v0.24.0
# ctr image export prometheus-v2.47.2.tar  quay.io/prometheus/prometheus:v2.47.2
# ctr image export agnhost-2.39.tar registry.k8s.io/e2e-test-images/agnhost:2.39
# ctr image export kube-state-metrics-v2.9.2.tar  registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.9.2
# ctr image export prometheus-adapter-v0.11.1.tar  registry.k8s.io/prometheus-adapter/prometheus-adapter:v0.11.1
# ctr image export harbor-adapter-trivy-2.9.1-debian-11-r0.tar  docker.io/bitnami/harbor-adapter-trivy:2.9.1-debian-11-r0
# ctr image export harbor-jobservice-2.9.1-debian-11-r1.tar  docker.io/bitnami/harbor-jobservice:2.9.1-debian-11-r1
# ctr image export harbor-registry-2.9.1-debian-11-r1.tar  docker.io/bitnami/harbor-registry:2.9.1-debian-11-r1
# ctr image export harbor-registryctl-2.9.1-debian-11-r1.tar  docker.io/bitnami/harbor-registryctl:2.9.1-debian-11-r1
# ctr image export redis-7.2.3-debian-11-r1.tar  docker.io/bitnami/redis:7.2.3-debian-11-r1
# ctr image export configmap-reload-v0.5.0.tar  docker.io/jimmidyson/configmap-reload:v0.5.0
# ctr image export kube-rbac-proxy-v0.15.0.tar  quay.io/brancz/kube-rbac-proxy:v0.15.0
# ctr image export pause-3.8.tar  registry.k8s.io/pause:3.8








# ctr image pull  docker.io/flannel/flannel-cni-plugin:v1.2.0
# ctr image pull  docker.io/flannel/flannel:v0.22.3
# ctr image pull  k8s.gcr.io/coredns/coredns:v1.8.4
# ctr image pull  k8s.gcr.io/etcd:3.5.0-0
# ctr image pull  k8s.gcr.io/kube-apiserver:v1.22.2
# ctr image pull  k8s.gcr.io/kube-controller-manager:v1.22.2
# ctr image pull  k8s.gcr.io/kube-proxy:v1.22.2
# ctr image pull  k8s.gcr.io/kube-scheduler:v1.22.2
# ctr image pull  k8s.gcr.io/pause:3.5
# ctr image pull  quay.io/brancz/kube-rbac-proxy:v0.15.0
# ctr image pull  quay.io/metallb/speaker:v0.13.11
# ctr image pull  quay.io/prometheus/node-exporter:v1.6.1
# ctr image pull  docker.io/bitnami/harbor-adapter-trivy:2.9.1-debian-11-r0
# ctr image pull  docker.io/bitnami/harbor-portal:2.9.1-debian-11-r0
# ctr image pull  docker.io/bitnami/mariadb:11.1.2-debian-11-r1
# ctr image pull  docker.io/bitnami/nginx:1.25.3-debian-11-r1
# ctr image pull  docker.io/bitnami/postgresql:13.13.0-debian-11-r4
# ctr image pull  docker.io/jimmidyson/configmap-reload:v0.5.0
# ctr image pull  docker.io/library/busybox:latest
# ctr image pull  docker.io/rancher/local-path-provisioner:v0.0.24
# ctr image pull  quay.io/metallb/controller:v0.13.11
# ctr image pull  quay.io/prometheus-operator/prometheus-config-reloader:v0.69.0
# ctr image pull  quay.io/prometheus-operator/prometheus-operator:v0.69.0
# ctr image pull  quay.io/prometheus/alertmanager:v0.26.0
# ctr image pull  quay.io/prometheus/blackbox-exporter:v0.24.0
# ctr image pull  quay.io/prometheus/prometheus:v2.47.2
# ctr image pull  registry.k8s.io/e2e-test-images/agnhost:2.39
# ctr image pull  registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.9.2
# ctr image pull  registry.k8s.io/prometheus-adapter/prometheus-adapter:v0.11.1
# ctr image pull  docker.io/bitnami/harbor-adapter-trivy:2.9.1-debian-11-r0
# ctr image pull  docker.io/bitnami/harbor-jobservice:2.9.1-debian-11-r1
# ctr image pull  docker.io/bitnami/harbor-registry:2.9.1-debian-11-r1
# ctr image pull   docker.io/bitnami/harbor-registryctl:2.9.1-debian-11-r1
# ctr image pull  docker.io/bitnami/redis:7.2.3-debian-11-r1
# ctr image pull  docker.io/jimmidyson/configmap-reload:v0.5.0
# ctr image pull  quay.io/brancz/kube-rbac-proxy:v0.15.0
# ctr image pull  registry.k8s.io/pause:3.8




if [ -d /mnt/images/ ]; then

# ctr -n=k8s.io images import  /mnt/images/flannel-cni-plugin-v1.2.0.tar
# ctr -n=k8s.io images import  /mnt/images/flannel-v0.22.3.tar
# ctr -n=k8s.io images import  /mnt/images/coredns-v1.8.4.tar
# ctr -n=k8s.io images import  /mnt/images/etcd-3.5.0-0.tar
# ctr -n=k8s.io images import  /mnt/images/kube-apiserver-v1.22.2.tar
# ctr -n=k8s.io images import  /mnt/images/kube-controller-manager-v1.22.2.tar
# ctr -n=k8s.io images import  /mnt/images/kube-proxy-v1.22.2.tar
# ctr -n=k8s.io images import  /mnt/images/kube-scheduler-v1.22.2.tar
# ctr -n=k8s.io images import  /mnt/images/pause-3.5.tar
# ctr -n=k8s.io images import  /mnt/images/kube-rbac-proxy-v0.15.0.tar
# ctr -n=k8s.io images import  /mnt/images/speaker-v0.13.11.tar
# ctr -n=k8s.io images import  /mnt/images/node-exporter-v1.6.1.tar
# ctr -n=k8s.io images import  /mnt/images/harbor-adapter-trivy-2.9.1-debian-11-r0.tar
# ctr -n=k8s.io images import  /mnt/images/harbor-portal-2.9.1-debian-11-r0.tar
# ctr -n=k8s.io images import  /mnt/images/mariadb-11.1.2-debian-11-r1.tar
# ctr -n=k8s.io images import  /mnt/images/nginx-1.25.3-debian-11-r1.tar
# ctr -n=k8s.io images import  /mnt/images/postgresql-13.13.0-debian-11-r4.tar
# ctr -n=k8s.io images import  /mnt/images/configmap-reload-v0.5.0.tar
# ctr -n=k8s.io images import  /mnt/images/busybox-latest.tar
# ctr -n=k8s.io images import  /mnt/images/local-path-provisioner-v0.0.24.tar
# ctr -n=k8s.io images import  /mnt/images/controller-v0.13.11.tar
# ctr -n=k8s.io images import  /mnt/images/prometheus-config-reloader-v0.69.0.tar
# ctr -n=k8s.io images import  /mnt/images/prometheus-operator-v0.69.0.tar
# ctr -n=k8s.io images import  /mnt/images/alertmanager-v0.26.0.tar
# ctr -n=k8s.io images import  /mnt/images/blackbox-exporter-v0.24.0.tar
# ctr -n=k8s.io images import  /mnt/images/prometheus-v2.47.2.tar
# ctr -n=k8s.io images import  /mnt/images/agnhost-2.39.tar
# ctr -n=k8s.io images import  /mnt/images/kube-state-metrics-v2.9.2.tar
# ctr -n=k8s.io images import  /mnt/images/prometheus-adapter-v0.11.1.tar
# ctr -n=k8s.io images import  /mnt/images/harbor-adapter-trivy-2.9.1-debian-11-r0.tar
# ctr -n=k8s.io images import  /mnt/images/harbor-jobservice-2.9.1-debian-11-r1.tar
# ctr -n=k8s.io images import  /mnt/images/harbor-registry-2.9.1-debian-11-r1.tar
# ctr -n=k8s.io images import  /mnt/images/harbor-registryctl-2.9.1-debian-11-r1.tar
# ctr -n=k8s.io images import  /mnt/images/redis-7.2.3-debian-11-r1.tar
# ctr -n=k8s.io images import  /mnt/images/configmap-reload-v0.5.0.tar
# ctr -n=k8s.io images import  /mnt/images/kube-rbac-proxy-v0.15.0.tar
# ctr -n=k8s.io images import  /mnt/images/pause-3.8.tar
# ctr -n=k8s.io images import  /mnt/images/wordpress-6.3.2-debian-11-r11.tar
# ctr -n=k8s.io images import  /mnt/images/csi-node-driver-registrar-v2.9.0.tar
# ctr -n=k8s.io images import  /mnt/images/livenessprobe-v2.11.0.tar
# ctr -n=k8s.io images import  /mnt/images/nfsplugin-v4.5.0.tar
# ctr -n=k8s.io images import  /mnt/images/csi-snapshotter-v6.3.1.tar



    IFS=$(echo -en "\n\b")
    templates=$(find "/mnt/images/" -type f | sort 2>/dev/null)
    for TEMPLATE in ${templates}; do
        ctr -n=k8s.io images import "${TEMPLATE}"
    done
 
fi


