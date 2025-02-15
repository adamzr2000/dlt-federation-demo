

```bash
./start_app.sh
```

```bash
curl http://localhost:9999/catalog/consumer-app.yaml
curl http://localhost:9999/topology/provider-net.yaml
```


```bash
screen -XS dummy-orchestrator quit

curl -O http://10.5.15.55:9999/catalog/consumer-app.yaml
```