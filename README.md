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
| **clinker** | Gene cluster comparison and visualisation (`clinker-py`) | 0.0.12, 0.0.19 – 0.0.32 |
| **cblaster** | Remote homologue detection and gene cluster search (ships with `cagecleaner`) | 1.3.9, 1.3.11 – 1.3.20, 1.4.0 |
| **defense‑finder** | Systematic search for anti‑phage defense systems | 1.0.9, 1.1.1, 1.2.0 – 1.2.2, 1.3.0, 2.0.0, 2.0.1 |
| **rgi** | Resistance Gene Identifier (CARD) | 5.0.0, 5.1.0 – 5.2.1, 6.0.0 – 6.0.5 |

All tools are installed from the [Bioconda](https://bioconda.github.io/)
package channel using **micromamba** running on an Alpine base image.
The resulting containers are small and suitable for use in pipelines,
Kubernetes jobs, or as base images for other workflows.

## Repository layout

```
/
├─ clinker/
│  ├─ 0.0.12/Dockerfile
│  ├─ 0.0.19/Dockerfile
│  └─ ...
├─ cblaster/
│  ├─ 1.3.9/Dockerfile
│  ├─ 1.3.11/Dockerfile
│  └─ ...
├─ defense-finder/
│  ├─ 1.0.9/Dockerfile
│  ├─ 2.0.1/Dockerfile
│  └─ ...
├─ rgi/
│  ├─ 5.0.0/Dockerfile
│  ├─ 6.0.5/Dockerfile
│  └─ ...
├─ tests/
│  ├─ clinker/test.sh
│  ├─ cblaster/test.sh
│  ├─ defense-finder/test.sh
│  └─ rgi/test.sh
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
docker build -t clinker:0.0.32          ./clinker/0.0.32
docker build -t cblaster:1.4.0          ./cblaster/1.4.0
docker build -t defense-finder:2.0.1    ./defense-finder/2.0.1
docker build -t rgi:6.0.5               ./rgi/6.0.5
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
runs on every push to `main` and on pull requests that touch a `Dockerfile`
or a test script. The logic is as follows:

1. A **detect‑changes** job determines which `tool/version` pairs are
   affected using `git diff`:
   - A changed `Dockerfile` → build, test, **and push** that specific version.
   - A changed test script → build and test **all** versions of that tool,
     but **no push**.
   - If nothing is affected the workflow exits early.
2. A **build** job uses a dynamic matrix of affected versions. For each
   entry it:
   - **Builds** the image locally
   - **Runs the functional test suite** against it
   - **Pushes** the image to GHCR only when the `Dockerfile` changed and
     the event is a push to `main`

The workflow also supports manual invocation via `workflow_dispatch`, which
rebuilds, tests, and pushes every image.

## Dependency updates

A `dependabot.yml` configuration keeps the GitHub Actions and the base images up to date. Pull requests are opened weekly
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
distributed under their respective licenses.
The container definitions are provided under the [MIT License](LICENSE).

---

_Maintained by andreassag_
