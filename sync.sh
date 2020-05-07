#!/bin/bash

set -euo pipefail


Sync__sat_semver.py() {
	URL=https://raw.githubusercontent.com/rbarrois/python-semanticversion/master/semantic_version/base.py
	script=$1; shift
	{
		echo '# -*- coding: utf-8 -*-'
		echo 'from __future__ import print_function'
		echo 'import sys'
		echo
	} >"$script"
	curl -#fSL "$URL" >>"$script"
	{
		echo
		# TODO: only_version doesn't account for semver rc/pre/alpha
		echo "only_version = re.compile(r'([0-9]+(\.[0-9]+)+)')" # TODO: use version_re from ^
		echo 'constraint = sys.argv[1]'
		echo 'refs = {}'
		echo 'for ref in sys.argv[2:]:'
		echo '    version = only_version.findall(ref)'
		echo '    if not version:'
		echo '        continue'
		echo '    refs[Version.coerce(version[0][0])] = ref'
		echo 'selected = SimpleSpec(constraint).select(refs)'
		echo 'if not selected:'
		echo '    exit(42)'
		echo 'print(refs[selected])'
	} >>"$script"
}


Sync__sat_semver.py ./sat_semver.py
