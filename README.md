# [bazel_upgradable](https://github.com/fenollp/bazel_upgradable)

Use `bazel sync` to upgrade & lock your dependencies.

Note: rules defined here download dependencies the same way `http_archive` does for best cache usage.

## Getting started

Add to your `.bazelrc` ([more info](https://blog.bazel.build/2018/09/28/first-class-resolved-file.html)):
```shell
# Dependencies locking
sync --experimental_repository_resolved_file=resolved.bzl
build --experimental_resolved_file_instead_of_workspace=resolved.bzl
build --experimental_repository_hash_file=resolved.bzl
build --experimental_verify_repository_rules=@bazel_tools//tools/build_defs/repo:git.bzl%git_repository
```

And to your `WORKSPACE`:
```python
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "bazel_upgradable",
    strip_prefix = "bazel_upgradable-master",
    type = "zip",
    url = "https://github.com/fenollp/bazel_upgradable/archive/master.zip",
)

load("@bazel_upgradable//rules:github.bzl", "upgradable_github_archive")

# Then add your dependencies here
```

### SemVer constraints
```python
upgradable_github_archive(
    name = "bazel_skylib",
    slug = "bazelbuild/bazel-skylib",
    tag = "~=0.8",
)
```

### Track HEAD
```python
upgradable_github_archive(
    name = "bazel_skylib",
    branch = "master",
    slug = "bazelbuild/bazel-skylib",
)
```

## Notes

Ongoing issues:
* https://github.com/bazelbuild/bazel/issues/11067

`bazel_upgradable` is an iteration on [bazel_lock](https://github.com/fenollp/bazel_lock).
