const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "6_5_shaders_exercise2",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(exe);

    // Use mach-glfw
    const glfw_dep = b.dependency("mach_glfw", .{
        .target = target,
        .optimize = optimize,
    });
    exe.addModule("mach-glfw", glfw_dep.module("mach-glfw"));
    @import("mach_glfw").link(glfw_dep.builder, exe);

    // Use OpenGL
    const opengl_dep = b.dependency("opengl", .{
        .target = target,
        .optimize = optimize,
    });
    exe.addModule("gl", opengl_dep.module("opengl"));

    // Use libs from LearnOpenGL
    const learnopengl_dep = b.dependency("learnopengl", .{
        .target = target,
        .optimize = optimize,
    });
    exe.addModule("learnopengl", learnopengl_dep.module("learnopengl"));

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Install the shader files
    const install_vs_step = b.addInstallFile(.{ .path = "src/6_5_shader.vs" }, "bin/6_5_shader.vs");
    run_step.dependOn(&install_vs_step.step);
    const install_fs_step = b.addInstallFile(.{ .path = "src/6_5_shader.fs" }, "bin/6_5_shader.fs");
    run_step.dependOn(&install_fs_step.step);
}
