const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");
const learnopengl = @import("learnopengl");
const stbi = @import("stbi");

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

    const shader = try learnopengl.Shader.init("6_3_shader.vs", "6_3_shader.fs");

    // set up vertex data and configure vertex attributes
    const vertices = [_]f32{
        -0.5, -0.5, 0.0, 1.0, 0.0, 0.0,
        0.5,  -0.5, 0.0, 0.0, 1.0, 0.0,
        0.0,  0.5,  0.0, 0.0, 0.0, 1.0,
    };
    var vaos = [_]c_uint{0};
    var vbos = [_]c_uint{0};
    gl.genVertexArrays(1, &vaos);
    defer gl.deleteVertexArrays(1, &vaos);
    gl.genBuffers(1, &vbos);
    defer gl.deleteBuffers(1, &vbos);

    const vao = vaos[0];
    const vbo = vbos[0];
    gl.bindVertexArray(vao);
    gl.bindBuffer(gl.ARRAY_BUFFER, vbo);
    gl.bufferData(gl.ARRAY_BUFFER, @sizeOf(f32) * vertices.len, &vertices, gl.STATIC_DRAW);

    gl.vertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 6 * @sizeOf(f32), null);
    gl.enableVertexAttribArray(0);
    const offset: [*c]c_uint = (3 * @sizeOf(f32));
    gl.vertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 6 * @sizeOf(f32), offset);
    gl.enableVertexAttribArray(1);

    gl.bindBuffer(gl.ARRAY_BUFFER, 0);
    gl.bindVertexArray(0);

    while (!window.shouldClose()) {
        processInput(window);

        gl.clearColor(0.2, 0.3, 0.3, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT);

        shader.use();
        gl.bindVertexArray(vao);
        gl.drawArrays(gl.TRIANGLES, 0, 3);

        glfw.pollEvents();
        window.swapBuffers();
    }
}

fn glGetProcAddress(_: glfw.GLProc, proc: [:0]const u8) ?*const anyopaque {
    return glfw.getProcAddress(proc);
}

fn frameBufferSizeCallback(_: glfw.Window, width: u32, height: u32) void {
    gl.viewport(0, 0, @intCast(width), @intCast(height));
}

fn processInput(window: glfw.Window) void {
    if (window.getKey(.escape) == .press) {
        window.setShouldClose(true);
    }
}
