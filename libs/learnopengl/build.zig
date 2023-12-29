const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const opengl_dep = b.dependency("opengl", .{
        .target = target,
        .optimize = optimize,
    });

    _ = b.addModule("learnopengl", .{
        .source_file = .{ .path = "src/Shader.zig" },
        .dependencies = &.{.{ .name = "gl", .module = opengl_dep.module("opengl") }},
    });
}
