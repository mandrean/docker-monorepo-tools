# Monorepo Tools

Tools for building and splitting monolithic repository from existing packages.
You can read about pros and cons of monorepo approach on the [Shopsys Framework Blog](https://blog.shopsys.com/how-to-maintain-multiple-git-repositories-with-ease-61a5e17152e0).

We created these scripts because we couldn't find a tool that would keep the git history of subpackages unchanged.

It may need a updated version of `git` (tested on `2.16.1`).

## Quick start

First download this repository so you can use the tools (eg. into `~/monorepo-tools`).

```
git clone https://github.com/shopsys/monorepo-tools ~/monorepo-tools
```

### Adding remotes to a new repository
You have to create a new git repository for your monorepo and add all your existing packages as remotes.
You can add as many remotes as you want.

```
git init
git remote add main-repository http://github.com/vendor/main-repository.git
git remote add package-alpha http://github.com/vendor/alpha.git
git remote add package-beta http://github.com/vendor/beta.git
git fetch --all
```

### Building the monorepo
Then you can build your monorepo using `monorepo_build.sh`.
Just list all your remotes as arguments.
Optionally you can specify a directory where the repository will be located by providing `<remote-name>:<subdirectory>`.

The command will rewrite history of all mentioned repositories as if they were developed in separate subdirectories.

Only branches `master` will be merged together, other branches will be kept only from first package to avoid possible branch name conflicts.

```
~/monorepo-tools/monorepo_build.sh \
    main-repository package-alpha:packages/alpha package-beta:packages/beta
```

This may take a while, depending on the size of your repositories.

Now your `master` branch should contain all packages in separate directories.
* main-repository/ - contains repository *vendor/main-repository*
* packages/
  * alpha/ - contains repository *vendor/alpha*
  * beta/ - contains repository *vendor/beta*

### Splitting into original repositories
You should develop all your packages in this repository from now on.

When you made your changes and would like to update the original repositories use `monorepo_build.sh` with the same arguments as before.

```
~/monorepo-tools/monorepo_split.sh \
    main-repository package-alpha:packages/alpha package-beta:packages/beta
```

This will push all relevant changes into all of your remotes.
Only `master` branches will be pushed.

It may again take a while, depending on the size of your monorepo.

## Reference

### [monorepo_build.sh](./monorepo_build.sh)
Build monorepo from specified remotes.  
You must first add the remotes by `git remote add <remote-name> <repository-url>` and fetch from them by `git fetch --all`.  
Final monorepo will contain all branches from the first remote and master branches of all remotes will be merged.  
If subdirectory is not specified remote name will be used instead.

Usage:  
`monorepo_build.sh <remote-name>[:<subdirectory>] <remote-name>[:<subdirectory>] ...`

Example:  
`monorepo_build.sh main-repository package-alpha:packages/alpha package-beta:packages/beta`

### [monorepo_split.sh](./monorepo_split.sh)
Split monorepo and push all master branches into specified remotes.  
You must first build the monorepo via `monorepo_build.sh` (uses same parameters as `monorepo_split.sh`).  
If subdirectory is not specified remote name will be used instead.

Usage:  
`monorepo_split.sh <remote-name>[:<subdirectory>] <remote-name>[:<subdirectory>] ...`

Example:  
`monorepo_split.sh main-repository package-alpha:packages/alpha package-beta:packages/beta`

### [rewrite_history_into.sh](./rewrite_history_into.sh)
Rewrite git history so that all filepaths are in a specific subdirectory.  
You can use arguments for `git rev-list` to specify what commits to rewrite (defaults to rewriting history of the checked-out branch).

Usage:  
`rewrite_history_into.sh <subdirectory> [<rev-list-args>]`

Examples:  
`rewrite_history_into.sh packages/alpha`  
`rewrite_history_into.sh main-repository --branches`

### [rewrite_history_from.sh](./rewrite_history_from.sh)
Rewrite git history so that only commits that made changes in a subdirectory are kept and rewrite all filepaths as if it was root.  
You can use arguments for `git rev-list` to specify what commits to rewrite (defaults to rewriting history of the checked-out branch).

Usage:  
`rewrite_history_from.sh <subdirectory> [<rev-list-args>]`

Examples:  
`rewrite_history_from.sh packages/alpha`  
`rewrite_history_from.sh main-repository --branches`

### [original_refs_restore.sh](./original_refs_restore.sh)
Restore original git history after rewrite.

Usage:  
`original_refs_restore.sh`

### [original_refs_wipe.sh](./original_refs_wipe.sh)
Wipe original git history after rewrite.

Usage:  
`original_refs_wipe.sh`

### [load_branches_from_remote.sh](./load_branches_from_remote.sh)
Delete all local branches and create all non-remote-tracking branches of a specified remote.

Usage:  
`load_branches_from_remote.sh <remote-name>`

Example:  
`load_branches_from_remote.sh origin`
