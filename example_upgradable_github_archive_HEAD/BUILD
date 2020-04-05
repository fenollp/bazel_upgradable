alias(
    name = "hello",
    actual = select({
        "on_windows": ":hello_on_windows.bat",
        "//conditions:default": ":hello_sh",
    }),
)

config_setting(
    name = "on_windows",
    constraint_values = ["@platforms//os:windows"],
)

sh_binary(
    name = "hello_sh",
    srcs = ["hello.sh"],
)

sh_binary(
    name = "hello_on_windows.bat",
    srcs = ["hello.bat"],
)
