const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "learnopengl",
        .root_source_file = .{ .path = "src/Shader.zig" },
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(lib);

    // Use OpenGL
    lib.addModule("gl", b.createModule(.{
        .source_file = .{ .path = "../../libs/opengl/gl33.zig" },
    }));
}
