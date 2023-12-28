const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "6_3_shaders_class",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(exe);

    // Use mach-glfw
    const glfw_dep = b.dependency("mach_glfw", .{
        .target = exe.target,
        .optimize = exe.optimize,
    });
    exe.addModule("mach-glfw", glfw_dep.module("mach-glfw"));
    @import("mach_glfw").link(glfw_dep.builder, exe);

    // Use OpenGL
    exe.addModule("gl", b.createModule(.{
        .source_file = .{ .path = "../../libs/opengl/gl33.zig" },
    }));

    // Use libs from LearnOpenGL
    const learnopengl_dep = b.dependency("learnopengl", . {
        .target = target,
        .optimize = optimize,
    });
    exe.addModule("learnopengl", learnopengl_dep.module("learnopengl"));

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
