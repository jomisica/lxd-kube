set -o xtrace
env

# This script will run after basic kubernetes boots. With it we can
# install and configure one or many applications for a given project.
# Using the kubeconfig generated during kubernetes cluster initialization.
# In this example it just connects to the cluster and lists the nodes.

#Using kubeconfig from this project
export KUBECONFIG="projects/${PROJECT_NAME}/kubernetes/kubeconfig/config"

# We need to have kubectl installed on the machine where this script is
# running to be able to communicate with the kubernetes cluster of the
# project in question.

# Wait for all nodes to be ready
local t=0
while [ $t -le 300 ]; do
    node_status=$(kubectl get nodes | grep NotReady)
    if [ $? -eq 1 ]; then
        echo "All nodes up..."
        break
    fi
    echo ${node_status}
    sleep 1
    sleep 1
    t=$((t + 1))
done

# At this moment, the nodes already have the Ready status.
# We can install our applications, configure the applications,
# using kubectl to apply templates, use helm, etc.

# In this example I just list the list of nodes in wide mode,
# to be able to see the status.
kubectl get nodes -o wide

exit
