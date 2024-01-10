const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const opengl_dep = b.dependency("opengl", .{
        .target = target,
        .optimize = optimize,
    });
    const zmath_dep = b.dependency("zmath", .{
        .target = target,
        .optimize = optimize,
    });

    _ = b.addModule("learnopengl", .{
        .source_file = .{ .path = "src/main.zig" },
        .dependencies = &.{
            .{ .name = "gl", .module = opengl_dep.module("opengl") },
            .{ .name = "zmath", .module = zmath_dep.module("zmath") },
        },
    });
}
