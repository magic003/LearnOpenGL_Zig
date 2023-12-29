const std = @import("std");

pub fn build(b: *std.Build) void {
    _ = b.standardTargetOptions(.{});
    _ = b.standardOptimizeOption(.{});

    _ = b.addModule("opengl", .{
        .source_file = .{ .path = "src/gl33.zig" },
    });
}
