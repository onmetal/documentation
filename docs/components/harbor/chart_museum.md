# Using helm to upload charts to Harbor Chart Museum

Add push plugin to helm
```bash
helm plugin install https://github.com/chartmuseum/helm-push
```
Add harbor to list of repos
```bash
helm repo add --username=USERNAME --password=PASSWORD harbor https://core.harbor.onmetal.de/chartrepo/library
```
Push your local chart to museum
```bash
helm push --username=USERNAME --password=PASSWORD path/to/chart_name harbor
```
Update remote chars
```bash
helm repo update
```
Install chart from harbor chart museum
```bash
helm install release_name harbor/chart_name
```