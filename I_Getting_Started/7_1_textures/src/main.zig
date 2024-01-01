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

    const shader = try learnopengl.Shader.init("7_1_texture.vs", "7_1_texture.fs");

    // set up vertex data and configure vertex attributes
    const vertices = [_]f32{
        // positions       // colors        // texture coords
        0.5, 0.5, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0, // top right
        0.5, -0.5, 0.0, 0.0, 1.0, 0.0, 1.0, 0.0, // bottom right
        -0.5, -0.5, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, // bottom left
        -0.5, 0.5, 0.0, 1.0, 1.0, 0.0, 0.0, 1.0, // top left
    };
    const indices = [_]c_uint{
        0, 1, 3,
        1, 2, 3,
    };

    var vao: c_uint = undefined;
    var vbo: c_uint = undefined;
    var ebo: c_uint = undefined;
    gl.genVertexArrays(1, &vao);
    defer gl.deleteVertexArrays(1, &vao);
    gl.genBuffers(1, &vbo);
    defer gl.deleteBuffers(1, &vbo);
    gl.genBuffers(1, &ebo);
    defer gl.deleteBuffers(1, &ebo);

    gl.bindVertexArray(vao);
    gl.bindBuffer(gl.ARRAY_BUFFER, vbo);
    gl.bufferData(gl.ARRAY_BUFFER, @sizeOf(f32) * vertices.len, &vertices, gl.STATIC_DRAW);
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo);
    gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, @sizeOf(c_uint) * indices.len, &indices, gl.STATIC_DRAW);

    gl.vertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 8 * @sizeOf(f32), null);
    gl.enableVertexAttribArray(0);
    const color_offset: [*c]c_uint = (3 * @sizeOf(f32));
    gl.vertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 8 * @sizeOf(f32), color_offset);
    gl.enableVertexAttribArray(1);
    const tex_offset: [*c]c_uint = (6 * @sizeOf(f32));
    gl.vertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, 8 * @sizeOf(f32), tex_offset);
    gl.enableVertexAttribArray(2);

    gl.bindBuffer(gl.ARRAY_BUFFER, 0);
    gl.bindVertexArray(0);

    // load and create a texture
    var texture: c_uint = undefined;
    gl.genTextures(1, &texture);
    gl.bindTexture(gl.TEXTURE_2D, texture);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
    var image_width: c_int = undefined;
    var image_height: c_int = undefined;
    var nr_channels: c_int = undefined;
    const data = stbi.stbi_load("images/container.jpg", &image_width, &image_height, &nr_channels, 0);
    if (data != null) {
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGB, image_width, image_height, 0, gl.RGB, gl.UNSIGNED_BYTE, data);
        gl.generateMipmap(gl.TEXTURE_2D);
    } else {
        std.log.err("Failed to load texture", .{});
    }
    stbi.stbi_image_free(data);

    while (!window.shouldClose()) {
        processInput(window);

        gl.clearColor(0.2, 0.3, 0.3, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT);

        shader.use();
        gl.bindTexture(gl.TEXTURE_2D, texture);
        gl.bindVertexArray(vao);
        gl.drawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, null);

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
