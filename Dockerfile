FROM ghcr.io/afritzler/mkdocs-material:8.1.8 

LABEL project=onmetal_documentation

WORKDIR /docs

COPY requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 8000

# Start development server by default
ENTRYPOINT ["mkdocs"]
CMD ["serve", "--dev-addr=0.0.0.0:8000"]
