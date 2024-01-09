const std = @import("std");
const math = std.math;
const glfw = @import("mach-glfw");
const gl = @import("gl");
const learnopengl = @import("learnopengl");
const stbi = @import("stbi");
const zmath = @import("zmath");

var camera_pos = zmath.f32x4(0.0, 0.0, 3.0, 0.0);
var camera_front = zmath.f32x4(0.0, 0.0, -1, 0.0);
var camera_up = zmath.f32x4(0.0, 1.0, 0.0, 0.0);

var delta_time: f32 = 0.0;
var last_frame: f32 = 0.0;

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

    gl.enable(gl.DEPTH_TEST);

    const shader = try learnopengl.Shader.init("10_2_camera.vs", "10_2_camera.fs");

    // set up vertex data and configure vertex attributes
    const vertices = [_]f32{
        // positions      // texture coords
        -0.5, -0.5, -0.5, 0.0, 0.0,
        0.5,  -0.5, -0.5, 1.0, 0.0,
        0.5,  0.5,  -0.5, 1.0, 1.0,
        0.5,  0.5,  -0.5, 1.0, 1.0,
        -0.5, 0.5,  -0.5, 0.0, 1.0,
        -0.5, -0.5, -0.5, 0.0, 0.0,

        -0.5, -0.5, 0.5,  0.0, 0.0,
        0.5,  -0.5, 0.5,  1.0, 0.0,
        0.5,  0.5,  0.5,  1.0, 1.0,
        0.5,  0.5,  0.5,  1.0, 1.0,
        -0.5, 0.5,  0.5,  0.0, 1.0,
        -0.5, -0.5, 0.5,  0.0, 0.0,

        -0.5, 0.5,  0.5,  1.0, 0.0,
        -0.5, 0.5,  -0.5, 1.0, 1.0,
        -0.5, -0.5, -0.5, 0.0, 1.0,
        -0.5, -0.5, -0.5, 0.0, 1.0,
        -0.5, -0.5, 0.5,  0.0, 0.0,
        -0.5, 0.5,  0.5,  1.0, 0.0,

        0.5,  0.5,  0.5,  1.0, 0.0,
        0.5,  0.5,  -0.5, 1.0, 1.0,
        0.5,  -0.5, -0.5, 0.0, 1.0,
        0.5,  -0.5, -0.5, 0.0, 1.0,
        0.5,  -0.5, 0.5,  0.0, 0.0,
        0.5,  0.5,  0.5,  1.0, 0.0,

        -0.5, -0.5, -0.5, 0.0, 1.0,
        0.5,  -0.5, -0.5, 1.0, 1.0,
        0.5,  -0.5, 0.5,  1.0, 0.0,
        0.5,  -0.5, 0.5,  1.0, 0.0,
        -0.5, -0.5, 0.5,  0.0, 0.0,
        -0.5, -0.5, -0.5, 0.0, 1.0,

        -0.5, 0.5,  -0.5, 0.0, 1.0,
        0.5,  0.5,  -0.5, 1.0, 1.0,
        0.5,  0.5,  0.5,  1.0, 0.0,
        0.5,  0.5,  0.5,  1.0, 0.0,
        -0.5, 0.5,  0.5,  0.0, 0.0,
        -0.5, 0.5,  -0.5, 0.0, 1.0,
    };
    const cube_positions = [_][3]f32{
        .{ 0.0, 0.0, 0.0 },
        .{ 2.0, 5.0, -15.0 },
        .{ -1.5, -2.2, -2.5 },
        .{ -3.8, -2.0, -12.3 },
        .{ 2.4, -0.4, -3.5 },
        .{ -1.7, 3.0, -7.5 },
        .{ 1.3, -2.0, -2.5 },
        .{ 1.5, 2.0, -2.5 },
        .{ 1.5, 0.2, -1.5 },
        .{ -1.3, 1.0, -1.5 },
    };

    var vao: c_uint = undefined;
    var vbo: c_uint = undefined;
    gl.genVertexArrays(1, &vao);
    defer gl.deleteVertexArrays(1, &vao);
    gl.genBuffers(1, &vbo);
    defer gl.deleteBuffers(1, &vbo);

    gl.bindVertexArray(vao);
    gl.bindBuffer(gl.ARRAY_BUFFER, vbo);
    gl.bufferData(gl.ARRAY_BUFFER, @sizeOf(f32) * vertices.len, &vertices, gl.STATIC_DRAW);

    gl.vertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 5 * @sizeOf(f32), null);
    gl.enableVertexAttribArray(0);
    const tex_offset: [*c]c_uint = (3 * @sizeOf(f32));
    gl.vertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, 5 * @sizeOf(f32), tex_offset);
    gl.enableVertexAttribArray(1);

    gl.bindBuffer(gl.ARRAY_BUFFER, 0);
    gl.bindVertexArray(0);

    // load and create texture1
    var texture1: c_uint = undefined;
    gl.genTextures(1, &texture1);
    gl.bindTexture(gl.TEXTURE_2D, texture1);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
    var image_width1: c_int = undefined;
    var image_height1: c_int = undefined;
    var nr_channels1: c_int = undefined;
    const data1 = stbi.stbi_load("images/container.jpg", &image_width1, &image_height1, &nr_channels1, 0);
    if (data1 != null) {
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGB, image_width1, image_height1, 0, gl.RGB, gl.UNSIGNED_BYTE, data1);
        gl.generateMipmap(gl.TEXTURE_2D);
    } else {
        std.log.err("Failed to load texture1", .{});
    }
    stbi.stbi_image_free(data1);

    // load and create texture1
    stbi.stbi_set_flip_vertically_on_load(1);
    var texture2: c_uint = undefined;
    gl.genTextures(1, &texture2);
    gl.bindTexture(gl.TEXTURE_2D, texture2);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
    var image_width2: c_int = undefined;
    var image_height2: c_int = undefined;
    var nr_channels2: c_int = undefined;
    const data2 = stbi.stbi_load("images/awesomeface.png", &image_width2, &image_height2, &nr_channels2, 0);
    if (data2 != null) {
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, image_width2, image_height2, 0, gl.RGBA, gl.UNSIGNED_BYTE, data2);
        gl.generateMipmap(gl.TEXTURE_2D);
    } else {
        std.log.err("Failed to load texture2", .{});
    }
    stbi.stbi_image_free(data2);

    // tell opengl for each sampler to which texture unit it belongs to (only has to be done once)
    shader.use();
    shader.setInt("texture1", 0);
    shader.setInt("texture2", 1);

    while (!window.shouldClose()) {
        processInput(window);

        gl.clearColor(0.2, 0.3, 0.3, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

        gl.activeTexture(gl.TEXTURE0);
        gl.bindTexture(gl.TEXTURE_2D, texture1);
        gl.activeTexture(gl.TEXTURE1);
        gl.bindTexture(gl.TEXTURE_2D, texture2);

        shader.use();
        gl.bindVertexArray(vao);

        const view = zmath.lookAtRh(
            camera_pos,
            camera_pos + camera_front,
            camera_up,
        );
        var view_mat: [4 * 4]f32 = undefined;
        zmath.storeMat(&view_mat, view);
        const projection = zmath.perspectiveFovRhGl(to_radians(45), 800.0 / 600.0, 0.1, 100.0);
        var projection_mat: [4 * 4]f32 = undefined;
        zmath.storeMat(&projection_mat, projection);

        const view_loc = gl.getUniformLocation(shader.ID, "view");
        gl.uniformMatrix4fv(view_loc, 1, gl.FALSE, &view_mat);
        const projection_loc = gl.getUniformLocation(shader.ID, "projection");
        gl.uniformMatrix4fv(projection_loc, 1, gl.FALSE, &projection_mat);

        for (cube_positions, 0..) |cube_position, i| {
            const translate = zmath.translation(cube_position[0], cube_position[1], cube_position[2]);

            const angle: f32 = 20.0 * @as(f32, @floatFromInt(i));
            const rotation = zmath.matFromAxisAngle(
                zmath.f32x4(0.5, 1.0, 0.0, 0.0),
                @floatCast(to_radians(angle)),
            );
            const model = zmath.mul(rotation, translate);
            var model_mat: [4 * 4]f32 = undefined;
            zmath.storeMat(&model_mat, model);

            const model_loc = gl.getUniformLocation(shader.ID, "model");
            gl.uniformMatrix4fv(model_loc, 1, gl.FALSE, &model_mat);

            gl.drawArrays(gl.TRIANGLES, 0, 36);
        }

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

    const current_frame = @as(f32, @floatCast(glfw.getTime()));
    delta_time = current_frame - last_frame;
    last_frame = current_frame;
    const camera_speed: f32 = 2.5 * delta_time;
    if (window.getKey(.w) == .press) {
        camera_pos += camera_front * zmath.f32x4s(camera_speed);
    }
    if (window.getKey(.s) == .press) {
        camera_pos -= camera_front * zmath.f32x4s(camera_speed);
    }
    if (window.getKey(.a) == .press) {
        camera_pos -= zmath.normalize3(zmath.cross3(camera_front, camera_up)) * zmath.f32x4s(camera_speed);
    }
    if (window.getKey(.d) == .press) {
        camera_pos += zmath.normalize3(zmath.cross3(camera_front, camera_up)) * zmath.f32x4s(camera_speed);
    }
}

inline fn to_radians(angle: f32) f32 {
    return math.pi * angle / 180.0;
}
