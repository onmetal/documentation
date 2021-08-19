# Gardener on Metal Documentation

This project is the main entrypoint for the Gardener on Metal documentation.

## Local development

To run the documentation project locally you can use the provided Makefile directives
to start a Docker container using the current repository content. Hot-reloading is enabled
so there is no need to restart the container after you made some changes.

```bash
make start
```

Stopped container instances can be cleaned up via

```bash
make clean
```

## Contribution guide

Contributions to this project can be done via Pull Requests either from a fork or inside a feature branch.
If you are new to git you can find more information on how to work with forks and branches [here](https://blog.scottlowe.org/2015/01/27/using-fork-branch-git-workflow/).

Once you have a local copy of the repository

```bash
git checkout -b my_new_docs_feature
```

Add your changes to the corresponding section or create a new subfolder in the `docs` folder if it is a new one

```bash
.
├── Dockerfile
├── LICENSE
├── README.md
├── docs
│   ├── architecture
│   └── concepts
└── mkdocs.yml
```

Once you finished your changes add and commit them to your branch

```bash
git add .
git commit -m "Something meaningful goes here"
git push origin my_new_docs_feature
```

Create now a Pull Request and wait for the Github actions check to turn green. If you encounter an issue and need to fix it
please `amend` commits and `force` push to your feature branch to update your Pull Request.

```bash
git add .
git commit --amend # typically no need to change the commit message
git push origin my_feature_branch -f
```

Please avoid creating PRs with multiple commits in the form of "fixed typo ABC". This keeps the PRs clean and the reviewers happy. :-)

## Adding mkdocs plugins

The `requirements.txt` file in this project contains the Python modules which should be installed during
a page build. Additional plugins for `mkdocs` should be added here.
