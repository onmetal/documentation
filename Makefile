IMAGE=onmetal/documentation

start:
	docker build -t $(IMAGE) .
	docker run -p 8000:8000 -v `pwd`/:/docs $(IMAGE)
.PHONY: setup-local-docker

clean:
	docker container prune --force --filter "label=project=onmetal_documentation"
.PHONY: clean-old-docker-container