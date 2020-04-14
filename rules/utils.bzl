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

def _ref_matching_exactly(lines, remote, ref_kind, ref):
    pattern = _ref_uri(ref_kind, ref)
    for line in lines:
        index = line.rfind(pattern)
        if index != -1:
            return line[:index]
    fail("There is no {} {} in {}".format(ref_kind, ref, remote))

def _refs_matching(lines, pattern):
    pattern_len = len(pattern)
    refs = {}
    for line in lines:
        index = line.rfind(pattern)
        if index != -1:
            commit, ref = line[:index], line[index + pattern_len:]
            refs[ref] = commit
    return refs

def _sat_semver_constraint(ctx, remote, ref_kind, constraint, refs):
    # TODO: migrate to Starlark to drop Python dependency
    script = ctx.path("../bazel_upgradable/rules/sat_semver.py")
    args = ["python", script, constraint]
    args.extend(refs.keys())
    result = ctx.execute(args)
    if result.return_code == 42:
        fail("No {} matching {} in {}".format(ref_kind, constraint, remote))
    if result.return_code != 0:
        fail("Failed running {}:\n{}".format(script, result.stderr))
    ref = result.stdout.splitlines()[0]
    return ref, refs[ref]

def _is_constraint(constraint):
    for op in ["<", "<=", "|=", "==", ">=", ">", "!=", "^", "~", "~="]:
        if len(constraint) > len(op) and op in constraint[:len(op)]:
            return True
    return False

def sat(ctx, remote, branch, tag):
    lines = _git_ls_remote(ctx, remote)

    ref_kind, constraint = "branch", branch
    if tag:
        ref_kind, constraint = "tag", tag

    if not _is_constraint(constraint):
        return constraint, _ref_matching_exactly(lines, remote, ref_kind, constraint)

    refs = _refs_matching(lines, _ref_uri(ref_kind))
    return _sat_semver_constraint(ctx, remote, ref_kind, constraint, refs)
