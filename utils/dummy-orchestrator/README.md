

```bash
./start_app.sh
```

```bash
curl http://localhost:9999/catalog/consumer-app.yaml
curl http://localhost:9999/topology/consumer-net.yaml
```

```bash
screen -XS dummy-orchestrator quit

curl -O http://10.5.15.55:9999/catalog/consumer-app.yaml
```

```bash
# groot (d6g-gw)
./vxlan_setup.sh -l 10.5.15.16 -r 10.5.98.105 -i eno1 -v 100 -p 4789 -n 192.168.70.0/24 -a 172.16.0.1/30 -g 172.16.0.2

# predict-6g-gw
./vxlan_setup.sh -l 10.5.98.105 -r 10.5.15.16 -i enp7s0 -v 100 -p 4789 -n 10.11.0.0/16 -a 172.16.0.2/30 -g 172.16.0.1
```