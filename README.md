# Shopsys Monorepo Tools

Dockerized version of [Shopsys Monorepo Tools](https://github.com/shopsys/monorepo-tools) for building and splitting monolithic repository from existing packages.

You can read about pros and cons of monorepo approach on the [Shopsys Framework Blog](https://blog.shopsys.com/how-to-maintain-multiple-git-repositories-with-ease-61a5e17152e0).

## Pre-requisites

* Git
* Docker

## Quick start

### 1. Preparing an empty repository with added remotes

You have to create a new git repository for your monorepo and add all your existing packages as remotes.
You can add as many remotes as you want.

In this example we will prepare 3 packages from GitHub for merging into monorepo.

```bash
$ git init
$ git remote add main-repository http://github.com/vendor/main-repository.git
$ git remote add package-alpha http://github.com/vendor/alpha.git
$ git remote add package-beta http://github.com/vendor/beta.git
$ git fetch --all --no-tags
```

### 2. Building the monorepo

Then you can build your monorepo using the `monorepo_build` image command.
Just list the names of all your previously added remotes as arguments.
Optionally you can specify a directory where the repository will be located by providing `<remote-name>:<subdirectory>`, otherwise remote name will be used.

The command will rewrite history of all mentioned repositories as if they were developed in separate subdirectories.

Only branches `master` will be merged together, other branches will be kept only from first package to avoid possible branch name conflicts.

```bash
$ docker run -v "$PWD:/work" -w /work -it mandrean/monorepo-tools:v7.0.0-alpha2 monorepo_build \
    main-repository package-alpha:packages/alpha package-beta:packages/beta
```

This may take a while, depending on the size of your repositories.

Now your `master` branch should contain all packages in separate directories. For our example it would mean:
* **main-repository/** - contains repository *vendor/main-repository*
* **packages/**
  * **alpha/** - contains repository *vendor/alpha*
  * **beta/** - contains repository *vendor/beta*

### 4. Splitting into original repositories

You should develop all your packages in this repository from now on.

When you made your changes and would like to update the original repositories use the `monorepo_split` image command with the same arguments as before.

```bash
$ docker run -v "$PWD:/work" -w /work -it mandrean/monorepo-tools:v7.0.0-alpha2 monorepo_split \
    main-repository package-alpha:packages/alpha package-beta:packages/beta
```

This will push all relevant changes into all of your remotes.
It will split and push your `master` branch along with all tags you added in this repository.
Other branches are not pushed.

It may again take a while, depending on the size of your monorepo.

## Reference

This is just a short description and usage of all the tools in the package.
For detailed information go to the scripts themselves and read the comments.

### [monorepo_build](https://github.com/shopsys/monorepo-tools/blob/v7.0.0-alpha2/monorepo_build.sh)

Build monorepo from specified remotes. The remotes must be already added to your repository and fetched.

Usage:
```bash
$ docker run -v "$PWD:/work" -w /work -it mandrean/monorepo-tools:v7.0.0-alpha2 monorepo_build \
    <remote-name>[:<subdirectory>] <remote-name>[:<subdirectory>] ...
```

### [monorepo_split](https://github.com/shopsys/monorepo-tools/blob/v7.0.0-alpha2/monorepo_split.sh)

Split monorepo built by `monorepo_build` and push all `master` branches along with all tags into specified remotes.

Usage:
```bash
$ docker run -v "$PWD:/work" -w /work -it mandrean/monorepo-tools:v7.0.0-alpha2 monorepo_split \
    <remote-name>[:<subdirectory>] <remote-name>[:<subdirectory>] ...
```

### [rewrite_history_into](https://github.com/shopsys/monorepo-tools/blob/v7.0.0-alpha2/rewrite_history_into.sh)

Rewrite git history (even tags) so that all filepaths are in a specific subdirectory.

Usage:
```bash
$ docker run -v "$PWD:/work" -w /work -it mandrean/monorepo-tools:v7.0.0-alpha2 rewrite_history_into \
    <subdirectory> [<rev-list-args>]
```

### [rewrite_history_from](https://github.com/shopsys/monorepo-tools/blob/v7.0.0-alpha2/rewrite_history_from.sh)

Rewrite git history (even tags) so that only commits that made changes in a subdirectory are kept and rewrite all filepaths as if it was root.

Usage:
```bash
$ docker run -v "$PWD:/work" -w /work -it mandrean/monorepo-tools:v7.0.0-alpha2 rewrite_history_from \
    <subdirectory> [<rev-list-args>]
```

### [original_refs_restore](https://github.com/shopsys/monorepo-tools/blob/v7.0.0-alpha2/original_refs_restore.sh)

Restore original git history after rewrite.

Usage:
```bash
$ docker run -v "$PWD:/work" -w /work -it mandrean/monorepo-tools:v7.0.0-alpha2 original_refs_restore
```

### [original_refs_wipe](https://github.com/shopsys/monorepo-tools/blob/v7.0.0-alpha2/original_refs_wipe.sh)

Wipe original git history after rewrite.

Usage:
```bash
$ docker run -v "$PWD:/work" -w /work -it mandrean/monorepo-tools:v7.0.0-alpha2 original_refs_wipe
```

### [load_branches_from_remote](https://github.com/shopsys/monorepo-tools/blob/v7.0.0-alpha2/load_branches_from_remote.sh)

Delete all local branches and create all non-remote-tracking branches of a specified remote.

Usage:
```bash
$ docker run -v "$PWD:/work" -w /work -it mandrean/monorepo-tools:v7.0.0-alpha2 load_branches_from_remote \
    <remote-name>
```
