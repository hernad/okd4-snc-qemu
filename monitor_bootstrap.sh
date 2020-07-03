 ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null core@bootstrap.snc.test "journalctl -b -f -u bootkube.service"
