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

echo
echo Updating scripts
echo

./sync.sh
git --no-pager diff -- . && [[ 0 -eq "$(git diff -- . | wc -l)" ]]


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

	rm $L
	$BAZEL sync
	make_resolved.bzl_hermetic
	git --no-pager diff . && [[ 0 -eq "$(git diff . | wc -l)" ]]

	popd >/dev/null
done


echo
echo Running locked, again
echo

for workspace in example_*upgradable*; do
	echo
	echo "$workspace"
	pushd "$workspace" >/dev/null

	$BAZEL run hello
	git --no-pager diff . && [[ 0 -eq "$(git diff . | wc -l)" ]]

	popd >/dev/null
done
git --no-pager diff -- example_* && [[ 0 -eq "$(git diff -- example_* | wc -l)" ]]
