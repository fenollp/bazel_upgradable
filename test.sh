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
echo Running locked
echo

for workspace in example_*; do
	echo
	echo "$workspace"
	pushd "$workspace" >/dev/null

	$BAZEL run hello

	popd >/dev/null
done
git --no-pager diff -- example_* && [[ 0 -eq "$(git diff -- example_* | wc -l)" ]]


echo
echo Upgrading dependencies
echo

for workspace in example_*; do
	echo
	echo "$workspace"
	pushd "$workspace" >/dev/null

	$BAZEL sync
	make_resolved.bzl_hermetic
	case "$workspace" in
	*)
		git --no-pager diff . && [[ 0 -eq "$(git diff . | wc -l)" ]]
	esac

	popd >/dev/null
done


echo
echo Running locked, again
echo

for workspace in example_*; do
	echo
	echo "$workspace"
	pushd "$workspace" >/dev/null

	$BAZEL run hello

	popd >/dev/null
done
git --no-pager diff -- example_* && [[ 0 -eq "$(git diff -- example_* | wc -l)" ]]
