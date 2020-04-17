#!/bin/bash

set -eu
set -o pipefail
git --no-pager diff -- example_* && [[ 0 -eq "$(git diff -- example_* | wc -l)" ]]
L=resolved.bzl

# FIXME: https://github.com/bazelbuild/bazel/issues/11067
make_resolved.bzl_hermetic() {
	grep -v -F '"definition_information": ' $L >$L~
	mv $L~ $L
}

snap_resolved() {
	snaped=$(mktemp)
	awk '/"@bazel_upgradable\/\/rules:repo.bzl%upgradable_repository",/,/"original_rule_class":/' $L \
	| grep -vF '"output_tree_hash":' \
	>"$snaped"
	echo "$snaped"
}

echo
echo Updating scripts
echo

./sync.sh
git --no-pager diff -- sync.sh && [[ 0 -eq "$(git diff -- sync.sh | wc -l)" ]]


echo
echo Running locked
echo

for workspace in example_*; do
	echo
	echo "$workspace"
	pushd "$workspace" >/dev/null

	$BAZEL run hello
	git --no-pager diff . && [[ 0 -eq "$(git diff . | wc -l)" ]]

	popd >/dev/null
done


echo
echo Upgrading dependencies
echo

for workspace in example_*; do
	echo
	echo "$workspace"
	pushd "$workspace" >/dev/null

	# FIXME: https://stackoverflow.com/questions/60864626/cannot-fetch-eigen-with-bazel-406-not-acceptable
	[[ "$workspace" = example_upgradable_gitlab_archive_constrained ]] && echo "SKIPPING GITLAB FOR NOW" && continue

	before=$(snap_resolved)
	rm $L
	$BAZEL sync
	make_resolved.bzl_hermetic
	after=$(snap_resolved)

    case "$workspace" in
        *upgradable*HEAD*)
            # Since this example follows HEAD we expect these values to change:
            # * sha256
            # * strip_prefix
            # * urls
            # * output_tree_hash
	        git --no-pager diff . && [[ 23 -eq "$(git diff . | wc -l)" ]] && git checkout -- $L
        ;;
        *)
	        diff --width=256 -y \
		         <(cat "$before" && rm "$before") \
		         <(cat "$after"  && rm "$after")
	        git add $L
	        git --no-pager diff . && [[ 0 -eq "$(git diff . | wc -l)" ]]
    esac

	popd >/dev/null
done


echo
echo Running locked, again
echo

for workspace in example_*; do
    [[ "$workspace" != *upgradable* ]] && continue
	echo
	echo "$workspace"
	pushd "$workspace" >/dev/null

	$BAZEL run hello
	git --no-pager diff . && [[ 0 -eq "$(git diff . | wc -l)" ]]

	popd >/dev/null
done
git --no-pager diff -- example_* && [[ 0 -eq "$(git diff -- example_* | wc -l)" ]]
