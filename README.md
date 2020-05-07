# [bazel_upgradable](https://github.com/fenollp/bazel_upgradable)

Use `bazel sync` to upgrade & lock your dependencies.

Notes
* The rule defined here downloads dependencies the same way `http_archive` does for best cache utilization.
* Dependencies hosted at https://github.com/bazelbuild also use https://mirror.bazel.build/

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
    strip_prefix = "bazel_upgradable-0.1.1",
    url = "https://github.com/fenollp/bazel_upgradable/archive/0.1.1.zip",
)

load("@bazel_upgradable//:rule.bzl", "upgradable_repository")

# Then add your dependencies here
# and run `bazel sync`
```

### Track HEAD
```python
upgradable_repository(
    name = "bazel_skylib",
    remote = "git://github.com/bazelbuild/bazel-skylib.git",
)
```

### SemVer constraints
```python
# Locking on major of a GitHub tag
upgradable_repository(
    name = "bazel_skylib",
    remote = "git://github.com/bazelbuild/bazel-skylib.git",
    tag = "~1",
)

# Blacklisting part of an interval of tags published on Gitlab
upgradable_repository(
    name = "radamsa",
    remote = "git@gitlab.com:akihe/radamsa.git",
    tag = "!=0.5",
)
```

### Depend on GitHub releases
Downstream example: https://github.com/voidstarHQ/voidstar
```python
upgradable_repository(
    name = "glfw_osx",
    build_file = "@//third_party:glfw3_osx.BUILD",
    # {tag} and {tag_digits} are expanded during dependency resolution
    release = "glfw-{tag_digits}.bin.MACOS.zip",
    remote = "git://github.com/glfw/glfw.git",
    tag = "~3",
)
```

## Notes

Ongoing issues:
* https://github.com/bazelbuild/bazel/issues/11067
* https://groups.google.com/forum/#!searchin/bazel-discuss/406%7Csort:date/bazel-discuss/9_ZqijN3OV4/Re3roXXPAQAJ

`bazel_upgradable` is an iteration on [bazel_lock](https://github.com/fenollp/bazel_lock).



## TODO

https://raw.githubusercontent.com/bazelbuild/bazel/ca2733c3ec4d0d5ebfe6b3c4b8dcee3c8855cf6b/tools/build_defs/repo/git.bzl
9fae1f5ee4c238064c845b6a99e5d6f8631f0c88    refs/tags/v0.6
https://docs.gitlab.com/ce/api/repositories.html#get-file-archive
https://gitlab.com/gitlab-org/gitlab-foss/-/issues/31530
https://gitlab.com/akihe/radamsa/-/archive/develop/radamsa-develop.tar.gz
https://gitlab.com/akihe/radamsa/-/archive/v0.6/radamsa-v0.6.tar.gz
https://gitlab.com/akihe/radamsa/-/archive/ab48466e6a7904792f7aaef31ce522e635aee3f2/radamsa-ab48466e6a7904792f7aaef31ce522e635aee3f2.tar.gz
