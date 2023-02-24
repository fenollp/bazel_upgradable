#!/bin/bash
set -euo pipefail

BAZEL=bazel
if command -v bazelisk; then
	BAZEL=bazelisk
fi
git --no-pager diff -- example_* && [[ 0 -eq "$(git diff -- example_* | wc -l)" ]]
L=resolved.bzl

# FIXME: https://github.com/bazelbuild/bazel/issues/11067
make_resolved.bzl_hermetic() {
	grep -v -F '"definition_information": ' $L >$L~
	mv $L~ $L
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
	[[ "$workspace" = example_upgradable_gitlab_archive_constrained ]] && echo "SKIPPING: example_upgradable_gitlab_archive_constrained" && continue

	cp $L before.py
	rm $L
	$BAZEL sync
	make_resolved.bzl_hermetic
	$BAZEL clean --expunge
	cp $L after.py

	set +e
	python3 ../diff.py "$PWD"
	diffed=$?
	set -e
	rm before.py after.py

	if [[ "$diffed" -ne 0 ]]; then
		case "$workspace" in
			*upgradable*HEAD*)
				# Since this example follows HEAD we expect these values to change:
				# * sha256
				# * strip_prefix
				# * urls
				# * output_tree_hash
				exit $diffed #FIXME
			;;
			*)
	            # There may be changes to values we do not care about here:
	            # * output_tree_hash
				exit $diffed #FIXME
		esac
	fi
	git checkout -- $L
	if [[ 0 -ne "$(git diff . | wc -l)" ]]; then
		git --no-pager diff .
		exit 1
	fi

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

echo PASSED
