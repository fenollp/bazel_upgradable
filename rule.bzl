### TODO: document setup

# TODO: ./sync.sh with https://raw.githubusercontent.com/bazelbuild/bazel/master/tools/build_defs/repo/http.bzl
load(
    "@bazel_tools//tools/build_defs/repo:utils.bzl",
    "patch",
    "read_netrc",
    "update_attrs",
    "use_netrc",
    "workspace_and_buildfile",
)

_AUTH_PATTERN_DOC = """An optional dict mapping host names to custom authorization patterns.

If a URL's host name is present in this dict the value will be used as a pattern when
generating the authorization header for the http request. This enables the use of custom
authorization schemes used in a lot of common cloud storage providers.

The pattern currently supports 2 tokens: <code>&lt;login&gt;</code> and
<code>&lt;password&gt;</code>, which are replaced with their equivalent value
in the netrc file for the same host name. After formatting, the result is set
as the value for the <code>Authorization</code> field of the HTTP request.

Example attribute and netrc for a http download to an oauth2 enabled API using a bearer token:

<pre>
auth_patterns = {
    "storage.cloudprovider.com": "Bearer &lt;password&gt;"
}
</pre>

netrc:

<pre>
machine storage.cloudprovider.com
        password RANDOM-TOKEN
</pre>

The final HTTP request would have the following header:

<pre>
Authorization: Bearer RANDOM-TOKEN
</pre>
"""

def _get_auth(ctx, urls):
    """Given the list of URLs obtain the correct auth dict."""
    if ctx.attr.netrc:
        netrc = read_netrc(ctx, ctx.attr.netrc)
        return use_netrc(netrc, urls, ctx.attr.auth_patterns)

    if "HOME" in ctx.os.environ and not ctx.os.name.startswith("windows"):
        netrcfile = "%s/.netrc" % (ctx.os.environ["HOME"])
        if ctx.execute(["test", "-f", netrcfile]).return_code == 0:
            netrc = read_netrc(ctx, netrcfile)
            return use_netrc(netrc, urls, ctx.attr.auth_patterns)

    if "USERPROFILE" in ctx.os.environ and ctx.os.name.startswith("windows"):
        netrcfile = "%s/.netrc" % (ctx.os.environ["USERPROFILE"])
        if ctx.path(netrcfile).exists:
            netrc = read_netrc(ctx, netrcfile)
            return use_netrc(netrc, urls, ctx.attr.auth_patterns)

    return {}

_http_archive_attrs = {
    "url": attr.string(
        doc =
            """A URL to a file that will be made available to Bazel.

This must be a file, http or https URL. Redirections are followed.
Authentication is not supported.

This parameter is to simplify the transition from the native http_archive
rule. More flexibility can be achieved by the urls parameter that allows
to specify alternative URLs to fetch from.
""",
    ),
    "urls": attr.string_list(
        doc =
            """A list of URLs to a file that will be made available to Bazel.

Each entry must be a file, http or https URL. Redirections are followed.
Authentication is not supported.""",
    ),
    "sha256": attr.string(
        doc = """The expected SHA-256 of the file downloaded.

This must match the SHA-256 of the file downloaded. _It is a security risk
to omit the SHA-256 as remote files can change._ At best omitting this
field will make your build non-hermetic. It is optional to make development
easier but should be set before shipping.""",
    ),
    "netrc": attr.string(
        doc = "Location of the .netrc file to use for authentication",
    ),
    "auth_patterns": attr.string_dict(
        doc = _AUTH_PATTERN_DOC,
    ),
    "canonical_id": attr.string(
        doc = """A canonical id of the archive downloaded.

If specified and non-empty, bazel will not take the archive from cache,
unless it was added to the cache by a request with the same canonical id.
""",
    ),
    "strip_prefix": attr.string(
        doc = """A directory prefix to strip from the extracted files.

Many archives contain a top-level directory that contains all of the useful
files in archive. Instead of needing to specify this prefix over and over
in the `build_file`, this field can be used to strip it from all of the
extracted files.

For example, suppose you are using `foo-lib-latest.zip`, which contains the
directory `foo-lib-1.2.3/` under which there is a `WORKSPACE` file and are
`src/`, `lib/`, and `test/` directories that contain the actual code you
wish to build. Specify `strip_prefix = "foo-lib-1.2.3"` to use the
`foo-lib-1.2.3` directory as your top-level directory.

Note that if there are files outside of this directory, they will be
discarded and inaccessible (e.g., a top-level license file). This includes
files/directories that start with the prefix but are not in the directory
(e.g., `foo-lib-1.2.3.release-notes`). If the specified prefix does not
match a directory in the archive, Bazel will return an error.""",
    ),
    "type": attr.string(
        doc = """The archive type of the downloaded file.

By default, the archive type is determined from the file extension of the
URL. If the file has no extension, you can explicitly specify one of the
following: `"zip"`, `"jar"`, `"war"`, `"tar"`, `"tar.gz"`, `"tgz"`,
`"tar.xz"`, or `tar.bz2`.""",
    ),
    "patches": attr.label_list(
        default = [],
        doc =
            "A list of files that are to be applied as patches after " +
            "extracting the archive. By default, it uses the Bazel-native patch implementation " +
            "which doesn't support fuzz match and binary patch, but Bazel will fall back to use " +
            "patch command line tool if `patch_tool` attribute is specified or there are " +
            "arguments other than `-p` in `patch_args` attribute.",
    ),
    "patch_tool": attr.string(
        default = "",
        doc = "The patch(1) utility to use. If this is specified, Bazel will use the specifed " +
              "patch tool instead of the Bazel-native patch implementation.",
    ),
    "patch_args": attr.string_list(
        default = ["-p0"],
        doc =
            "The arguments given to the patch tool. Defaults to -p0, " +
            "however -p1 will usually be needed for patches generated by " +
            "git. If multiple -p arguments are specified, the last one will take effect." +
            "If arguments other than -p are specified, Bazel will fall back to use patch " +
            "command line tool instead of the Bazel-native patch implementation. When falling " +
            "back to patch command line tool and patch_tool attribute is not specified, " +
            "`patch` will be used.",
    ),
    "patch_cmds": attr.string_list(
        default = [],
        doc = "Sequence of Bash commands to be applied on Linux/Macos after patches are applied.",
    ),
    "patch_cmds_win": attr.string_list(
        default = [],
        doc = "Sequence of Powershell commands to be applied on Windows after patches are " +
              "applied. If this attribute is not set, patch_cmds will be executed on Windows, " +
              "which requires Bash binary to exist.",
    ),
    "build_file": attr.label(
        allow_single_file = True,
        doc =
            "The file to use as the BUILD file for this repository." +
            "This attribute is an absolute label (use '@//' for the main " +
            "repo). The file does not need to be named BUILD, but can " +
            "be (something like BUILD.new-repo-name may work well for " +
            "distinguishing it from the repository's actual BUILD files. " +
            "Either build_file or build_file_content can be specified, but " +
            "not both.",
    ),
    "build_file_content": attr.string(
        doc =
            "The content for the BUILD file for this repository. " +
            "Either build_file or build_file_content can be specified, but " +
            "not both.",
    ),
    "workspace_file": attr.label(
        doc =
            "The file to use as the `WORKSPACE` file for this repository. " +
            "Either `workspace_file` or `workspace_file_content` can be " +
            "specified, or neither, but not both.",
    ),
    "workspace_file_content": attr.string(
        doc =
            "The content for the WORKSPACE file for this repository. " +
            "Either `workspace_file` or `workspace_file_content` can be " +
            "specified, or neither, but not both.",
    ),
}

_rule_attrs = _http_archive_attrs
_rule_attrs.pop("url")
_rule_attrs["branch"] = attr.string()  #TODO: document
_rule_attrs["release"] = attr.string()  #TODO: document
_rule_attrs["remote"] = attr.string(mandatory = True)  #TODO: document
_rule_attrs["tag"] = attr.string()  #TODO: document

def _please_report(fname, o):
    fail("BUG! Please report: {}({})".format(fname, o))

def _type_for(**o):
    if o["hosting"] == "github":
        return "tar.gz"  # Often fewer bytes than "zip"
    elif o["hosting"] == "gitlab":
        return "tar.bz2"
    _please_report("_type_for", o)

def _prefix_for(**o):
    if o["hosting"] in ["github", "gitlab"]:
        return "{repo}-{commit}".format(**o)
    _please_report("_prefix_for", o)

def _archive_for(**o):
    if o["hosting"] == "github":
        return "https://{host}/{owner}/{repo}/archive/{commit}".format(**o)
    if o["hosting"] == "gitlab":
        # FIXME return "https://{host}/{owner}/{repo}/-/archive/{commit}/{repo}-{commit}".format(**o)
        return "https://{host}/{owner}/{repo}/-/archive/{ref}/{repo}-{ref}".format(**o)
    _please_report("_archive_for", o)

def _git_ls_remote(ctx, remote):
    result = ctx.execute(["git", "ls-remote", "--refs", remote])
    if result.return_code != 0:
        fail("Could not fetch remote refs from {}:\n{}".format(remote, result.stderr))
    return [
        line
        for line in result.stdout.splitlines()
        if
        # Remove dereferenced tags
        line.rfind("^{}") == -1 and
        # Remove GitHub's pull requests
        line.find("refs/pull/") == -1 and
        # Remove Gitlab's merge requests
        line.find("refs/merge-requests/") == -1
    ]

def _ref_uri(ref_kind, ref = ""):
    if ref_kind == "tag":
        return "\trefs/tags/" + ref
    return "\trefs/heads/" + ref

def _ref_matching_exactly(lines, o):
    pattern = _ref_uri(o["ref_kind"], o["constraint"])
    for line in lines:
        index = line.rfind(pattern)
        if index != -1:
            return line[:index]
    fail("There is no {ref_kind} {constraint} in {remote}".format(**o))

def _refs_matching(lines, pattern):
    pattern_len = len(pattern)
    refs = {}
    for line in lines:
        index = line.rfind(pattern)
        if index != -1:
            commit, ref = line[:index], line[index + pattern_len:]
            refs[ref] = commit
    return refs

def _sat_semver_constraint(ctx, constraint, refs):
    # TODO: migrate to Starlark to drop Python dependency
    script = ctx.path("../bazel_upgradable/sat_semver.py")
    args = ["python", script, constraint]
    args.extend(refs.keys())
    result = ctx.execute(args)
    if result.return_code == 42:
        return None, None
    if result.return_code != 0:
        fail("Failed running {}:\n{}".format(script, result.stderr))
    ref = result.stdout.splitlines()[0]
    return ref, refs[ref]

def _is_constraint(constraint):
    for op in ["<", "<=", "|=", "==", ">=", ">", "!=", "^", "~", "~="]:
        if len(constraint) > len(op) and op in constraint[:len(op)]:
            return True
    return False

def _sat_git_ref(ctx, o):
    lines = _git_ls_remote(ctx, o["remote"])

    if not _is_constraint(o["constraint"]):
        return o["constraint"], _ref_matching_exactly(lines, o)

    refs = _refs_matching(lines, _ref_uri(o["ref_kind"]))
    ref, commit = _sat_semver_constraint(ctx, o["constraint"], refs)
    if not ref or not commit:
        fail("No {ref_kind} matching {constraint} in {remote}".format(**o))
    return ref, commit

def _python_executable(ctx):
    # TODO: drop once the fog clears up...
    if ctx.execute(["python3", "--version"]).return_code == 0:
        return "python3"
    return "python"

def _github_releases(ctx, o):
    script = ctx.path("../bazel_upgradable/github_release_refs.py")
    token = ""
    if "GITHUB_TOKEN" in ctx.os.environ:
        token = ctx.os.environ["GITHUB_TOKEN"]
    result = ctx.execute([
        _python_executable(ctx),
        script,
        "https://api.github.com/repos/{owner}/{repo}/releases".format(**o),
        token,
        o["release"],
    ])
    if result.return_code != 0:
        fail("Failed running {}:\n{}".format(script, result.stderr))
    return {line.split("\t")[0]: (
        line.split("\t")[1],
        line.split("\t")[2],
        line.split("\t")[3],
    ) for line in result.stdout.splitlines()}

def _sat_github_release(ctx, o):
    tags = _github_releases(ctx, o)
    tag, details = _sat_semver_constraint(ctx, o["constraint"], tags)
    if not tag:
        fail("No release {constraint} matches {release} in {remote}".format(**o))
    (tag_digits, ty, url) = details
    return tag, tag_digits, url, ty

def _from_remote(remote):
    scheme, host, owner, repo = None, None, None, None
    remote_slashed = remote.split("/")
    remote_exploded = remote \
        .replace("@", " ") \
        .replace(":", " ") \
        .replace("/", " ") \
        .split(" ")
    if len(remote_slashed) == 5:
        scheme, _, host, owner, repo = remote_slashed
    elif len(remote_exploded) == 4:
        scheme, host, owner, repo = remote_exploded
    else:
        fail("A remote must be of the form scheme://host/owner/repo or https://host/owner/repo")
    if scheme not in ["git:", "https:"]:
        fail("Unsupported scheme '{}'".format(scheme))
    if repo.endswith(".git"):
        repo = repo[:-len(".git")]
    hosting = None
    if host == "github.com":
        hosting = "github"
    elif host == "gitlab.com":
        hosting = "gitlab"
    else:
        fail("Unsupported hosting with {}".format(host))
    return {
        "host": host,
        "hosting": hosting,
        "owner": owner,
        "remote": remote,
        "repo": repo,
        "scheme": scheme,
    }

def _impl_for_upgradable_repository(ctx):
    """Implementation of the upgradable_repository rule."""
    if ctx.attr.build_file and ctx.attr.build_file_content:
        fail("Only one of build_file and build_file_content can be provided.")

    if ctx.attr.tag and ctx.attr.branch:
        fail("Exactly one of branch or tag must be provided")
    if not ctx.attr.tag and ctx.attr.release:
        fail("A tag constraint must be provided")
    branch = ctx.attr.branch
    if not ctx.attr.tag and not branch:
        branch = "master"

    o = _from_remote(ctx.attr.remote)
    o["release"] = ctx.attr.release
    o.update(ref_kind = "branch", constraint = branch)
    if ctx.attr.tag:
        o.update(ref_kind = "tag", constraint = ctx.attr.tag)

    # TODO: use "GITHUB_TOKEN" in ctx.os.environ || netrc or other auth means

    typ = ctx.attr.type
    all_urls = ctx.attr.urls
    strip_prefix = ctx.attr.strip_prefix
    if len([None for x in [ctx.attr.sha256, typ, all_urls, strip_prefix] if not x]) != 0:
        if not o["release"]:
            ref, commit = _sat_git_ref(ctx, o)
            o.update(commit = commit, ref = ref)
            print(o["ref_kind"].title() + " {ref} of {remote} satisfies constraint {constraint} (commit = {commit})".format(**o))
            typ = _type_for(**o)
            all_urls = [_archive_for(**o) + "." + typ]
            strip_prefix = _prefix_for(**o)
        elif o["hosting"] == "github":
            tag, tag_digits, url, ty = _sat_github_release(ctx, o)
            name = o["release"].format(tag = tag, tag_digits = tag_digits)
            args = [tag, o["remote"], o["constraint"], name]
            print("Release {} of {} satisfies constraint {} (matching name {})".format(*args))
            if strip_prefix:
                # Replaces {tag} and {tag_digits} wherever strip_prefix contains them
                # TODO? also replace {commit} (requires another API call)
                strip_prefix = strip_prefix.format(tag = tag, tag_digits = tag_digits)
            if not typ:
                typ = ty
            all_urls = [url]
        else:
            fail("Fetching releases of {host} is unsupported".format(**o))

        # Attempt Bazel's mirroring of bazelbuild archives
        mirrored = ""
        for url in all_urls:
            maybe_split = url.split("https://github.com/bazelbuild/")
            if len(maybe_split) == 2:
                mirrored = "https://mirror.bazel.build/github.com/bazelbuild/" + maybe_split[1]
        if mirrored and mirrored not in all_urls:
            all_urls.append(mirrored)

    auth = _get_auth(ctx, all_urls)
    download_info = ctx.download_and_extract(
        all_urls,
        "",
        ctx.attr.sha256,
        typ,
        strip_prefix,
        canonical_id = ctx.attr.canonical_id,
        auth = auth,
    )
    workspace_and_buildfile(ctx)
    patch(ctx)
    return update_attrs(ctx.attr, _rule_attrs.keys(), {
        "sha256": download_info.sha256,
        "strip_prefix": strip_prefix,
        "type": typ,
        "urls": all_urls,
    })

upgradable_repository = repository_rule(
    implementation = _impl_for_upgradable_repository,
    attrs = _rule_attrs,
    doc = "",  #TODO: document
)
