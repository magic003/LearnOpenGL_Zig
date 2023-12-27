const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");

pub fn main() !void {
    _ = glfw.init(.{});
    defer glfw.terminate();

    const hints = glfw.Window.Hints{
        .context_version_major = 3,
        .context_version_minor = 3,
        .opengl_profile = .opengl_core_profile,
    };
    const width = 800;
    const height = 600;
    const window = glfw.Window.create(width, height, "LearnOpenGL", null, null, hints) orelse {
        std.log.err("Failed to create GLFW window: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    };
    defer window.destroy();

    glfw.makeContextCurrent(window);

    const proc: glfw.GLProc = undefined;
    try gl.load(proc, glGetProcAddress);

    gl.viewport(0, 0, @intCast(width), @intCast(height));
    window.setFramebufferSizeCallback(frameBufferSizeCallback);

    while (!window.shouldClose()) {
        window.swapBuffers();
        glfw.pollEvents();
    }
}

fn glGetProcAddress(_: glfw.GLProc, proc: [:0]const u8) ?*const anyopaque {
    return glfw.getProcAddress(proc);
}

fn frameBufferSizeCallback(_: glfw.Window, width: u32, height: u32) void {
    gl.viewport(0, 0, @intCast(width), @intCast(height));
}
