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
    "remote_java_tools",
    "remote_java_tools_darwin",
    "remote_java_tools_linux",
    "remote_java_tools_windows",
    "remotejdk10_linux",
    "remotejdk10_linux_aarch64",
    "remotejdk10_macos",
    "remotejdk10_win",
    "remotejdk11_linux",
    "remotejdk11_linux_aarch64",
    "remotejdk11_linux_aarch64_toolchain_config_repo",
    "remotejdk11_linux_ppc64le",
    "remotejdk11_linux_ppc64le_toolchain_config_repo",
    "remotejdk11_linux_s390x",
    "remotejdk11_linux_s390x_toolchain_config_repo",
    "remotejdk11_linux_toolchain_config_repo",
    "remotejdk11_macos",
    "remotejdk11_macos_aarch64",
    "remotejdk11_macos_aarch64_toolchain_config_repo",
    "remotejdk11_macos_toolchain_config_repo",
    "remotejdk11_win",
    "remotejdk11_win_arm64",
    "remotejdk11_win_arm64_toolchain_config_repo",
    "remotejdk11_win_toolchain_config_repo",
    "remotejdk14_linux",
    "remotejdk14_macos",
    "remotejdk14_win",
    "remotejdk15_linux",
    "remotejdk15_linux_toolchain_config_repo",
    "remotejdk15_macos",
    "remotejdk15_macos_aarch64",
    "remotejdk15_macos_aarch64_toolchain_config_repo",
    "remotejdk15_macos_toolchain_config_repo",
    "remotejdk15_win",
    "remotejdk15_win_toolchain_config_repo",
    "remotejdk16_linux",
    "remotejdk16_linux_toolchain_config_repo",
    "remotejdk16_macos",
    "remotejdk16_macos_aarch64",
    "remotejdk16_macos_aarch64_toolchain_config_repo",
    "remotejdk16_macos_toolchain_config_repo",
    "remotejdk16_win",
    "remotejdk16_win_toolchain_config_repo",
    "remotejdk17_linux",
    "remotejdk17_linux_toolchain_config_repo",
    "remotejdk17_macos",
    "remotejdk17_macos_aarch64",
    "remotejdk17_macos_aarch64_toolchain_config_repo",
    "remotejdk17_macos_toolchain_config_repo",
    "remotejdk17_win",
    "remotejdk17_win_arm64",
    "remotejdk17_win_arm64_toolchain_config_repo",
    "remotejdk17_win_toolchain_config_repo",
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

keys = sorted(set(list(b.keys()) + list(a.keys())))
mismatched = [k for k in keys if k not in b or k not in a]
if len(mismatched) != 0:
    print("Unexpected keys:")
    print(mismatched)
    print("add these to IGNORED maybe?")
    exit(1)

for name in keys:
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
