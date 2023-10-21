# This script has been tested on Ubuntu 20.04
# For other versions of Ubuntu, you might need some tweaking

echo "Install essential packages"
apt install -qq -y net-tools curl ssh software-properties-common >/dev/null

echo "Install containerd runtime"
apt update -qq 2>/dev/null
apt install -qq -y containerd apt-transport-https 2>/dev/null
echo return: $?


mkdir /etc/containerd >/dev/null
containerd config default > /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

echo "Add apt repo for kubernetes"
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"

echo "Install Kubernetes components (kubeadm, kubelet and kubectl)"
apt install -qq -y kubeadm=${K8S_VERSION}-00 kubelet=${K8S_VERSION}-00 kubectl=${K8S_VERSION}-00  2>/dev/null
echo return: $?

echo 'KUBELET_EXTRA_ARGS="--fail-swap-on=false"' > /etc/default/kubelet
systemctl restart kubelet

apt autoremove -y  >/dev/null

