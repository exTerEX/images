<!--
This repository contains container definitions for bioinformatics
utilities. Each tool is organised by release version so that we can
build, test and publish immutable images for every supported release
while also maintaining convenient `latest`, `major` and `minor` tags.
-->

# Container images for bioinformatics tools

This repository provides a simple, reproducible way to build, test and push
Docker/OCI images for the following command‑line utilities:

| Tool | Description | Versions |
|------|-------------|----------|
| **aragorn** | tRNA and tmRNA detection | 1.2.36, 1.2.38, 1.2.41 |
| **tRNAscan‑SE** | Transfer RNA gene prediction | 2.0.0, 2.0.3, 2.0.5 – 2.0.12 |
| **clinker** | Gene cluster comparison and visualisation (`clinker-py`) | 0.0.12, 0.0.19 – 0.0.32 |
| **cblaster** | Remote homologue detection and gene cluster search (ships with `cagecleaner`) | 1.3.9, 1.3.11 – 1.3.20, 1.4.0 |

All tools are installed from the [Bioconda](https://bioconda.github.io/)
package channel using **micromamba** running on an Alpine base image. The
resulting containers are small and suitable for use in pipelines,
Kubernetes jobs, or as base images for other workflows.

## Repository layout

```
/
├─ aragorn/
│  ├─ 1.2.36/Dockerfile
│  ├─ 1.2.38/Dockerfile
│  └─ 1.2.41/Dockerfile
├─ trnascan-se/
│  ├─ 2.0.0/Dockerfile
│  ├─ 2.0.3/Dockerfile
│  └─ ...
├─ clinker/
│  ├─ 0.0.12/Dockerfile
│  ├─ 0.0.19/Dockerfile
│  └─ ...
├─ cblaster/
│  ├─ 1.3.9/Dockerfile
│  ├─ 1.3.11/Dockerfile
│  └─ ...
├─ tests/
│  ├─ aragorn/test.sh
│  ├─ trnascan-se/test.sh
│  ├─ clinker/test.sh
│  └─ cblaster/test.sh
├─ shared/
├─ .github/
│  ├─ workflows/build-container.yml        # CI workflow
│  └─ dependabot.yml                       # dependency updates
└─ README.md
```

Each version directory contains a nearly‑identical Dockerfile that
parameterises the package version via an `ARG`. New releases can be added
simply by creating a new directory and copying one of the existing
Dockerfiles, then updating the `ARG` value.

## Building locally

You can build an image manually with `docker build` or `podman`:

```sh
docker build -t aragorn:1.2.41   ./aragorn/1.2.41
docker build -t clinker:0.0.32   ./clinker/0.0.32
docker build -t cblaster:1.4.0   ./cblaster/1.4.0
```

Replace the tool name and version string as needed.
The containers rely only on the packages installed by micromamba, so no
additional build dependencies are required.

## Testing locally

Each tool has a test suite under `tests/<tool>/test.sh`. The script
expects two arguments: the image reference and the expected version.

```sh
docker build -t test/clinker:0.0.32 ./clinker/0.0.32
tests/clinker/test.sh test/clinker:0.0.32 0.0.32
```

## Continuous Integration

A single GitHub Actions workflow (`.github/workflows/build-container.yml`)
runs on every push to `main` and on pull requests that touch a `Dockerfile`,
test script, or shared file. The logic is as follows:

1. A **detect‑changes** job determines which `tool/version` pairs have
   changed using `git diff`. Changes to `tests/` or `shared/` also trigger
   the relevant images. If nothing is affected the workflow exits early.
2. A **build** job uses a dynamic matrix containing the affected versions.
   For each entry it:
   - **Builds** the image locally
   - **Runs the functional test suite** against it
   - **Pushes** the image to GHCR (only on pushes to `main`)

The workflow also supports manual invocation via `workflow_dispatch`, which
rebuilds and tests every image.

### Tagging scheme

For each version built the following tags are pushed:

* `tool:X.Y.Z` – exact version
* `tool:X.Y` – latest minor release (only for the highest version in that
  minor series)
* `tool:X` – latest major release (only for the highest version overall)
* `tool:latest` – alias for the current major release

For example, building `aragorn/1.2.41` produces:
```
ghcr.io/.../aragorn:1.2.41
ghcr.io/.../aragorn:1.2
ghcr.io/.../aragorn:1
ghcr.io/.../aragorn:latest
```

## Dependency updates

A `dependabot.yml` configuration keeps the GitHub Actions and the base
`mambaorg/micromamba` images up to date. Pull requests are opened weekly
whenever new versions are available; they are labeled `dependencies` and
either `github-actions` or `docker`.

## Contributing

1. Create a new `<tool>/<version>/Dockerfile` directory (copy an existing one
   and update the `ARG`).
2. Add or update the test script in `tests/<tool>/test.sh`.
3. Build and test locally to verify.
4. Commit and push; the CI will test and publish images automatically.

## License & Attribution

This repository does not contain the tools themselves, which are
distributed under their respective licenses (GPLv3 for ARAGORN, etc.).
The container definitions are provided under the [MIT License](LICENSE).

---

_Maintained by exTerEX – built with GitHub Actions and micromamba._
