# Uploading docker image to Harbor Registry

Login to repo
```bash
docker login core.harbor.onmetal.de
```

Tag your image
```bash
docker tag local-server/app_path/app_name:version core.harbor.onmetal.de/app_path/app_name:version
```

Push your image
```bash
docker push core.harbor.onmetal.de/app_path/app_name:version
```

(Optionally) Logout
```bash
docker logout core.harbor.onmetal.de
```