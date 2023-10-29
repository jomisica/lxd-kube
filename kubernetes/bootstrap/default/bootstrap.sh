set -o xtrace

env


# This script has been tested on Ubuntu 18.04, 20.04, 22.04
# For other versions of Ubuntu, you might need some tweaking

echo "Install essential packages"
#apt install -qq -y net-tools curl ssh software-properties-common 

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

