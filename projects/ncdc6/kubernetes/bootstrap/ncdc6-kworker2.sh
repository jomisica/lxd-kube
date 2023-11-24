set -o xtrace

env

# This script has been tested on Ubuntu 18.04, 20.04, 22.04
# For other versions of Ubuntu, you might need some tweaking

echo "Install essential packages"
#apt install -qq -y net-tools curl ssh software-properties-common 

echo "Install runtime"
apt update -qq
apt install -qq -y apt-transport-https ca-certificates net-tools curl
echo return: $?


source /etc/os-release
OS=x${NAME}_${VERSION_ID}
CRIO_VERSION=${K8S_VERSION%.*}
echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /"|sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
echo "deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$CRIO_VERSION/$OS/ /"|sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$CRIO_VERSION.list
curl -L https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$CRIO_VERSION/$OS/Release.key | sudo apt-key add -
curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | sudo apt-key add -
apt update -y
apt install cri-o cri-o-runc -y

# insecure rep
cat >> /etc/containers/registries.conf <<EOF
[[registry]]
insecure = true
location = "core.harbor.domain"
EOF


systemctl enable crio.service
systemctl start crio.service
apt install cri-tools -y



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
