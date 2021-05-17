IMAGE=onmetal/documentation

start-local-docker:
	docker build -t $(IMAGE) .
	docker run -p 8000:8000 -v `pwd`/:/docs $(IMAGE)
.PHONY: setup-local-docker

clean-stopped-docker-container:
	docker container prune --force --filter "label=project=onmetal_documentation"
.PHONY: clean-old-docker-container