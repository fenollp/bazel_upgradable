# -*- coding: utf-8 -*-

import json
import sys
sys.path.append(sys.argv[1])

import before
import after

IGNORED = [
    "android_tools",
    "local_config_cc",
    "local_config_cc_toolchains",
    "local_config_sh",
    "local_config_xcode",
    "local_jdk",
    "remote_coverage_tools",
    "remote_java_tools_darwin",
    "remote_java_tools_linux",
    "remote_java_tools_windows",
    "remotejdk10_linux",
    "remotejdk10_linux_aarch64",
    "remotejdk10_macos",
    "remotejdk10_win",
    "remotejdk11_linux",
    "remotejdk11_linux_aarch64",
    "remotejdk11_macos",
    "remotejdk11_win",
    "remotejdk_linux",
    "remotejdk_linux_aarch64",
    "remotejdk_macos",
    "remotejdk_win",
    "rules_cc",
    "rules_java",
    "rules_proto",
]

b = {}
for x in before.resolved:
    if '@bazel_tools' not in x['original_rule_class']:
        continue
    name = x['original_attributes']['name']
    if name in IGNORED:
        continue
    b[name] = x

a = {}
for x in after.resolved:
    if '@bazel_tools' not in x['original_rule_class']:
        continue
    name = x['original_attributes']['name']
    if name in IGNORED:
        continue
    a[name] = x

for name in sorted(set(list(b.keys()) + list(a.keys()))):
    xb = b[name]
    xa = a[name]
    d = {k: xa[k] for k in set(xa) - set(xb)}
    if d:
        print(name)
        print("Before:")
        print(json.dumps(xb, indent=4, sort_keys=True))
        print("Before:")
        print(json.dumps(xa, indent=4, sort_keys=True))
        print("Difference:")
        print(json.dumps(d, indent=4, sort_keys=True))
        exit(len(2))
