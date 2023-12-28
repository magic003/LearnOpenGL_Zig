const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");

const vertex_sharder_source =
    \\#version 330 core
    \\
    \\layout (location = 0) in vec3 aPos;
    \\
    \\void main()
    \\{
    \\    gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
    \\}
;
const fragment_sharder_source1 =
    \\#version 330 core
    \\
    \\out vec4 FragColor;
    \\
    \\void main()
    \\{
    \\    FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
    \\}
;
const fragment_sharder_source2 =
    \\#version 330 core
    \\
    \\out vec4 FragColor;
    \\
    \\void main()
    \\{
    \\    FragColor = vec4(1.0f, 1.0f, 0.0f, 1.0f);
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

    const fragment_shader1 = gl.createShader(gl.FRAGMENT_SHADER);
    const fragment_sources1 = [_][*c]const u8{&fragment_sharder_source1.*};
    gl.shaderSource(fragment_shader1, fragment_sources1.len, &fragment_sources1, null);
    gl.compileShader(fragment_shader1);
    gl.getShaderiv(fragment_shader1, gl.COMPILE_STATUS, &success);
    if (success[0] == 0) {
        gl.getShaderInfoLog(fragment_shader1, 512, null, &info_log);
        std.log.err("Fragment shader1 compilation failed: {s}", .{info_log});
    }

    const fragment_shader2 = gl.createShader(gl.FRAGMENT_SHADER);
    const fragment_sources2 = [_][*c]const u8{&fragment_sharder_source2.*};
    gl.shaderSource(fragment_shader2, fragment_sources2.len, &fragment_sources2, null);
    gl.compileShader(fragment_shader2);
    gl.getShaderiv(fragment_shader2, gl.COMPILE_STATUS, &success);
    if (success[0] == 0) {
        gl.getShaderInfoLog(fragment_shader2, 512, null, &info_log);
        std.log.err("Fragment shader2 compilation failed: {s}", .{info_log});
    }

    const shader_program1 = gl.createProgram();
    defer gl.deleteProgram(shader_program1);
    gl.attachShader(shader_program1, vertex_shader);
    gl.attachShader(shader_program1, fragment_shader1);
    gl.linkProgram(shader_program1);
    gl.getProgramiv(shader_program1, gl.LINK_STATUS, &success);
    if (success[0] == 0) {
        gl.getProgramInfoLog(shader_program1, 512, null, &info_log);
        std.log.err("Shader program1 link failed: {s}", .{info_log});
    }

    const shader_program2 = gl.createProgram();
    defer gl.deleteProgram(shader_program2);
    gl.attachShader(shader_program2, vertex_shader);
    gl.attachShader(shader_program2, fragment_shader2);
    gl.linkProgram(shader_program2);
    gl.getProgramiv(shader_program2, gl.LINK_STATUS, &success);
    if (success[0] == 0) {
        gl.getProgramInfoLog(shader_program2, 512, null, &info_log);
        std.log.err("Shader program2 link failed: {s}", .{info_log});
    }

    gl.deleteShader(vertex_shader);
    gl.deleteShader(fragment_shader1);
    gl.deleteShader(fragment_shader2);

    // set up vertex data and configure vertex attributes
    const triangle1 = [_]f32{
        -0.5, -0.5, 0.0,
        0.5,  -0.5, 0.0,
        0.0,  0.5,  0.0,
    };
    const triangle2 = [_]f32{
        0.0,  -0.5, 0.0,
        0.9,  -0.5, 0.0,
        0.45, 0.5,  0.0,
    };
    var vaos = [_]c_uint{ 0, 0 };
    var vbos = [_]c_uint{ 0, 0 };
    gl.genVertexArrays(2, &vaos);
    defer gl.deleteVertexArrays(2, &vaos);
    gl.genBuffers(2, &vbos);
    defer gl.deleteBuffers(2, &vbos);

    gl.bindVertexArray(vaos[0]);
    gl.bindBuffer(gl.ARRAY_BUFFER, vbos[0]);
    gl.bufferData(gl.ARRAY_BUFFER, @sizeOf(f32) * triangle1.len, &triangle1, gl.STATIC_DRAW);

    gl.vertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * @sizeOf(f32), null);
    gl.enableVertexAttribArray(0);

    gl.bindVertexArray(vaos[1]);
    gl.bindBuffer(gl.ARRAY_BUFFER, vbos[1]);
    gl.bufferData(gl.ARRAY_BUFFER, @sizeOf(f32) * triangle2.len, &triangle2, gl.STATIC_DRAW);

    gl.vertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * @sizeOf(f32), null);
    gl.enableVertexAttribArray(0);

    while (!window.shouldClose()) {
        processInput(window);

        gl.clearColor(0.2, 0.3, 0.3, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT);

        gl.useProgram(shader_program1);
        gl.bindVertexArray(vaos[0]);
        gl.drawArrays(gl.TRIANGLES, 0, 3);

        gl.useProgram(shader_program2);
        gl.bindVertexArray(vaos[1]);
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
