const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = b.addModule("stbi", .{
        .source_file = .{ .path = "src/c.zig" },
    });

    const lib = b.addStaticLibrary(.{
        .name = "stbi",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = .{ .path = "src/c.zig" },
        .link_libc = true,
        .target = target,
        .optimize = optimize,
    });

    lib.addIncludePath(.{ .path = "src/include/" });

    lib.addCSourceFiles(.{
        .files = &[_][]const u8{"src/include/stb_image.c"},
        .flags = &[_][]const u8{ "-g", "-O3" },
    });

    b.installArtifact(lib);
}
