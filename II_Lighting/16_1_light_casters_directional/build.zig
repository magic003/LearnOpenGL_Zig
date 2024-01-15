const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "16_1_light_casters_directional",
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

    // Use zmath
    const zmath_dep = b.dependency("zmath", .{
        .target = target,
        .optimize = optimize,
    });
    exe.addModule("zmath", zmath_dep.module("zmath"));

    // Use stbi
    const stbi_dep = b.dependency("stbi", .{
        .target = target,
        .optimize = optimize,
    });
    exe.addIncludePath(.{
        .path = stbi_dep.builder.pathFromRoot(stbi_dep.module("stb_image_include").source_file.path),
    });
    exe.addModule("stbi", stbi_dep.module("stbi"));
    exe.linkLibrary(stbi_dep.artifact("stbi"));

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Install the shaders
    const install_shaders_step = b.addInstallDirectory(.{
        .source_dir = .{ .path = "shaders/" },
        .install_dir = .bin,
        .install_subdir = "shaders/",
    });
    exe.step.dependOn(&install_shaders_step.step);

    // Install the images
    const install_image_step = b.addInstallDirectory(.{
        .source_dir = .{ .path = "images/" },
        .install_dir = .bin,
        .install_subdir = "images/",
    });
    exe.step.dependOn(&install_image_step.step);
}
