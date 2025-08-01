#!/bin/bash

# Exit on error
set -e

err_report() {
    echo "Exited with error on line $1"
}
trap 'err_report $LINENO' ERR

# Create directories for each version
mkdir -p certs/1.16 certs/1.33 certs/mixed certs/patched-133

# Function to generate CA using kubeadm in a container
generate_ca() {
    local version=$1
    local kubeadm_binary=$2
    local output_dir=$3

    echo "Generating CA for Kubernetes $version..."

    # Run kubeadm in a container to generate CA
    docker run --rm \
        -v "$(pwd):/workdir" \
        -v "$(pwd)/$kubeadm_binary:/usr/local/bin/kubeadm" \
        -w /workdir \
        alpine:3.19 \
        sh -c "
            apk add --no-cache ca-certificates
            mkdir -p /etc/kubernetes/pki
            kubeadm init phase certs ca
            cp /etc/kubernetes/pki/ca.crt /workdir/$output_dir/
            cp /etc/kubernetes/pki/ca.key /workdir/$output_dir/
        "
}

# Function to generate API server cert using existing CA
generate_api_cert() {
    local ca_dir=$1
    local kubeadm_binary=$2
    local output_dir=$3

    echo "Generating API server certificate using CA from $ca_dir with $kubeadm_binary..."

    docker run --rm \
        -v "$(pwd):/workdir" \
        -v "$(pwd)/$kubeadm_binary:/usr/local/bin/kubeadm" \
        -w /workdir \
        alpine:3.19 \
        sh -c "
            apk add --no-cache ca-certificates
            mkdir -p /etc/kubernetes/pki
            cp /workdir/$ca_dir/ca.crt /etc/kubernetes/pki/
            cp /workdir/$ca_dir/ca.key /etc/kubernetes/pki/
            kubeadm init phase certs apiserver
            cp /etc/kubernetes/pki/apiserver.crt /workdir/$output_dir/
            cp /etc/kubernetes/pki/apiserver.key /workdir/$output_dir/
        "
}

# Generate CAs for both versions
generate_ca "1.16" "kubeadm-116" "certs/1.16"
generate_ca "1.33" "kubeadm-133" "certs/1.33"

# Generate API server certificates
generate_api_cert "certs/1.16" "kubeadm-116" "certs/1.16"
generate_api_cert "certs/1.33" "kubeadm-133" "certs/1.33"
generate_api_cert "certs/1.16" "kubeadm-133" "certs/mixed"
generate_api_cert "certs/1.16" "kubeadm-patched" "certs/patched-133"


echo "Certificates generated successfully!"
echo "Saving certificate information to text files..."

# Save certificate information to text files
for version in "1.16" "1.33" "mixed" "patched-133"; do
    echo "Saving certificate information for version $version..."

    # CA certificate (only for 1.16 and 1.33)
    if [ -f "certs/$version/ca.crt" ]; then
        openssl x509 -in certs/$version/ca.crt -text -noout > certs/$version/ca.crt.txt
    fi

    # API server certificate
    if [ -f "certs/$version/apiserver.crt" ]; then
        openssl x509 -in certs/$version/apiserver.crt -text -noout > certs/$version/apiserver.crt.txt
    fi
done

echo "Certificate information saved to text files in the certs directory."
