## Overview
GPU Slicing, also known as Multi-Instance GPU (MIG) for NVIDIA GPUs, allows a single physical GPU to be partitioned into multiple smaller instances. This can significantly optimize resource utilization and cost efficiency for workloads that don't require a full GPU. This feature is particularly beneficial for machine learning and AI workloads where tasks can be parallelized across multiple GPU instances.

## Enabling GPU Slicing on EKS
To enable GPU Slicing on EKS clusters, particularly those with Karpenter Autoscaler, follow these steps:

**Verify GPU Support:**
Ensure that your EKS nodes support NVIDIA GPUs that have MIG capabilities, such as the NVIDIA A100.

**Install NVIDIA Drivers and GPU Operator:**
Use the NVIDIA GPU Operator to manage and configure GPU resources on your Kubernetes cluster.

**Configure MIG on GPU Nodes:** 
Set up MIG on GPU nodes to partition the GPU into multiple instances.

**Update Karpenter Configuration:** 
Modify Karpenter configuration to recognize and scale based on the availability of GPU slices.

## An example Step-by-Step Implementation
**Step 1: Verify GPU Support**
Ensure that your EKS nodes are using NVIDIA GPUs that support MIG (e.g., NVIDIA A100).

**Step 2: Install NVIDIA Drivers and GPU Operator**
**Install NVIDIA Device Plugin:** this can be done through a daemonset deployment

Create a nvidia-device-plugin DaemonSet to expose GPUs to your Kubernetes cluster.
**yaml**

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: nvidia-device-plugin-daemonset
  namespace: kube-system
  labels:
    name: nvidia-device-plugin-ds
spec:
  selector:
    matchLabels:
      name: nvidia-device-plugin-ds
  updateStrategy:
    type: RollingUpdate
  template:
    metadata:
      labels:
        name: nvidia-device-plugin-ds
    spec:
      tolerations:
      - key: nvidia.com/gpu
        operator: Exists
        effect: NoSchedule
      containers:
      - image: nvidia/k8s-device-plugin:1.0.0-beta4
        name: nvidia-device-plugin-ctr
        env:
        - name: FAIL_ON_INIT_ERROR
          value: "false"
        resources:
          limits:
            nvidia.com/gpu: 1
```

**Install NVIDIA GPU Operator:**

Use Helm to install the NVIDIA GPU Operator which manages the NVIDIA drivers and other components needed for GPU support.
```sh
helm repo add nvidia https://nvidia.github.io/gpu-operator
helm repo update
helm install --wait --generate-name nvidia/gpu-operator
```

**Step 3:** Configure MIG on GPU Nodes
**SSH into each GPU node and configure MIG:**

```sh
sudo nvidia-smi -mig 1
Create MIG instances. For example, to create 7 MIG instances on an A100 GPU:
```

```sh
sudo nvidia-smi mig -cgi 0,1,2,3,4,5,6 -C
```

**Verify MIG configuration:**
```sh
nvidia-smi mig -lgi
```

Step 4: Update Karpenter Configuration using provisioners and workloads yaml