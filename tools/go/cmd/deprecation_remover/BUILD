load("@io_bazel_rules_go//go:def.bzl", "go_binary", "go_library")

go_binary(
    name = "deprecation_remover",
    embed = [":deprecation_remover_lib"],
    visibility = ["//visibility:public"],
)

go_library(
    name = "deprecation_remover_lib",
    srcs = ["main.go"],
    importpath = "dev.mpy.UmbraCore/tools/go/cmd/deprecation_remover",
    visibility = ["//visibility:private"],
)
