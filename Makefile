.PHONY: build build-client run-server run-client run-client-py312 run-client-py313 download-kubeadm generate-certs

# Default target
all: build build-client

download-kubeadm:
	curl -L --remote-name-all https://dl.k8s.io/release/v1.33.0/bin/linux/amd64/kubeadm
	chmod +x kubeadm
	mv kubeadm kubeadm-133
	curl -L --remote-name-all https://dl.k8s.io/release/v1.16.9/bin/linux/amd64/kubeadm
	chmod +x kubeadm
	mv kubeadm kubeadm-116

# Generate certificates using the script
generate-certs: download-kubeadm
	chmod +x generate-certs.sh
	./generate-certs.sh

# Build the server container
build:
	docker build -t kubeadm-test .

# Run the server container
run-server: build
	docker run --rm \
		-d \
		--name kubernetes \
		--hostname kubernetes \
		-p 443:443 \
		--cap-add=NET_BIND_SERVICE \
		-v $(PWD)/certs/:/app/certs/ \
		kubeadm-test \
		-cert /app/certs/patched-133/apiserver.crt \
		-key /app/certs/patched-133/apiserver.key


# Run the client directly with Python 3.12
run-client-py312:
	docker run --rm \
		--add-host kubernetes:host-gateway \
		-e KUBERNETES_HOSTNAME=kubernetes \
		-e KUBERNETES_CA_CERT=/app/certs/1.16/ca.crt \
		-v $(PWD)/certs/:/app/certs/ \
		-v $(PWD)/client.py:/app/client.py \
		-w /app \
		python:3.12-alpine \
		python client.py

# Run the client directly with Python 3.13
run-client-py313:
	docker run --rm \
		--add-host kubernetes:host-gateway \
		-e KUBERNETES_HOSTNAME=kubernetes \
		-e KUBERNETES_CA_CERT=/app/certs/1.16/ca.crt \
		-v $(PWD)/certs/:/app/certs/ \
		-v $(PWD)/client.py:/app/client.py \
		-w /app \
		python:3.13-alpine \
		python client.py 

	
# Run the client directly with Python 3.13
run-client-py313-no-strict:
	docker run --rm \
		--add-host kubernetes:host-gateway \
		-e KUBERNETES_HOSTNAME=kubernetes \
		-e KUBERNETES_CA_CERT=/app/certs/1.16/ca.crt \
		-e VERIFY_X509_STRICT=false \
		-v $(PWD)/certs/:/app/certs/ \
		-v $(PWD)/client.py:/app/client.py \
		-w /app \
		python:3.13-alpine \
		python client.py 