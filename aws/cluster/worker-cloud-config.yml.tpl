#cloud-config

coreos:
  units:
    - name: format-ebs-volume.service
      command: start
      content: |
        [Unit]
        Description=Formats the ebs volume if needed
        Before=docker.service
        [Service]
        Type=oneshot
        RemainAfterExit=yes
        ExecStart=/bin/bash -c '(/usr/sbin/blkid -t TYPE=ext4 | grep /dev/xvdb) || (/usr/sbin/wipefs -fa /dev/xvdb && /usr/sbin/mkfs.ext4 /dev/xvdb)'
    - name: var-lib-docker.mount
      command: start
      content: |
        [Unit]
        Description=Mount ephemeral to /var/lib/docker
        Requires=format-ebs-volume.service
        After=format-ebs-volume.service
        [Mount]
        What=/dev/xvdb
        Where=/var/lib/docker
        Type=ext4
    - name: docker.service
      drop-ins:
      - name: 10-wait-docker.conf
          content: |
            [Unit]
            After=var-lib-docker.mount
            Requires=var-lib-docker.mount
    - name: systemd-networkd.service
      command: stop
    - name: 00-eth0.network
      runtime: true
      content: |
        [Match]
        Name=eth0

        [Network]
        DNS=10.0.0.2
        UseDomains=yes
        Domains=${cluster_name} eu-west-1.compute.internal
    - name: systemd-networkd.service
      command: restart
  fleet:
    metadata: "role=worker,region=${region}"
    public-ip: "$public_ipv4"
    etcd_servers: "http://localhost:2379"
  locksmith:
    endpoint: "http://localhost:2379"
  update:
    reboot-strategy: best-effort
manage_etc_hosts: localhost
