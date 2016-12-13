#cloud-config

coreos:
  fleet:
    metadata: "role=master,region=${region}"
    public-ip: "$public_ipv4"
    etcd_servers: "http://localhost:2379"
  locksmith:
    endpoint: "http://localhost:2379"
  update:
    reboot-strategy: best-effort