const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");

const vertex_sharder_source =
    \\#version 330 core
    \\
    \\layout (location = 0) in vec3 aPos;
    \\layout (location = 1) in vec3 aColor;
    \\
    \\out vec3 ourColor;
    \\
    \\void main()
    \\{
    \\    gl_Position = vec4(aPos, 1.0);
    \\    ourColor = aColor;
    \\}
;
const fragment_sharder_source =
    \\#version 330 core
    \\
    \\in vec3 ourColor;
    \\
    \\out vec4 FragColor;
    \\
    \\void main()
    \\{
    \\    FragColor = vec4(ourColor, 1.0);
    \\}
;

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

    // build and compile the shader program
    const vertex_shader = gl.createShader(gl.VERTEX_SHADER);
    const vertext_sources = [_][*c]const u8{&vertex_sharder_source.*};
    gl.shaderSource(vertex_shader, vertext_sources.len, &vertext_sources, null);
    gl.compileShader(vertex_shader);
    var success = [_]c_int{0};
    var info_log: [512]u8 = undefined;
    gl.getShaderiv(vertex_shader, gl.COMPILE_STATUS, &success);
    if (success[0] == 0) {
        gl.getShaderInfoLog(vertex_shader, 512, null, &info_log);
        std.log.err("Vertext shader compilation failed: {s}", .{info_log});
    }

    const fragment_shader = gl.createShader(gl.FRAGMENT_SHADER);
    const fragment_sources = [_][*c]const u8{&fragment_sharder_source.*};
    gl.shaderSource(fragment_shader, fragment_sources.len, &fragment_sources, null);
    gl.compileShader(fragment_shader);
    gl.getShaderiv(fragment_shader, gl.COMPILE_STATUS, &success);
    if (success[0] == 0) {
        gl.getShaderInfoLog(fragment_shader, 512, null, &info_log);
        std.log.err("Fragment shader compilation failed: {s}", .{info_log});
    }

    const shader_program = gl.createProgram();
    defer gl.deleteProgram(shader_program);
    gl.attachShader(shader_program, vertex_shader);
    gl.attachShader(shader_program, fragment_shader);
    gl.linkProgram(shader_program);
    gl.getProgramiv(shader_program, gl.LINK_STATUS, &success);
    if (success[0] == 0) {
        gl.getProgramInfoLog(shader_program, 512, null, &info_log);
        std.log.err("Shader program link failed: {s}", .{info_log});
    }
    gl.deleteShader(vertex_shader);
    gl.deleteShader(fragment_shader);

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

        gl.useProgram(shader_program);
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
