 ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null core@master-1.snc.test "journalctl -b -f -u kubelet.service"
