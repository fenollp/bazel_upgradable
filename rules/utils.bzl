def git_refs(ctx, remote):
    # result = ctx.execute(["git", "ls-remote", "--refs", remote])
    result = ctx.execute(["git", "ls-remote", remote])
    if result.return_code != 0:
        fail("Could not fetch remote refs from {}:\n{}".format(remote, result.stderr))
    refs = {}
    for line in result.stdout.split("\n"):
        if line == "":
            continue
        if "refs/pull/" in line:
            # TODO: decide if we should keep pull request refs
            continue
        commit, ref = line.split("\t")
        if "refs/" in ref:
            # Only HEAD ref should not start with "refs/"
            ref = ref[5:]
        refs[ref] = commit
    return refs

def sat_constraint(ctx, constraint, refs):
    if constraint == "HEAD":
        return refs[constraint], constraint
    fail("TODO")
