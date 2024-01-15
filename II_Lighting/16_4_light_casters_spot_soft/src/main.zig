const std = @import("std");
const math = std.math;
const glfw = @import("mach-glfw");
const gl = @import("gl");
const learnopengl = @import("learnopengl");
const zmath = @import("zmath");
const stbi = @import("stbi");

var camera = learnopengl.Camera.init(
    zmath.loadArr3(.{ 0.0, 0.0, 5.0 }),
    zmath.loadArr3(.{ 0.0, 1.0, 0.0 }),
    -90.0,
    0.0,
);

var delta_time: f32 = 0.0;
var last_frame: f32 = 0.0;

var first_mouse = true;
var last_x: f32 = 400;
var last_y: f32 = 300;

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

    window.setCursorPosCallback(mouseCallback);
    window.setScrollCallback(scrollCallback);

    window.setInputMode(.cursor, .disabled);

    const proc: glfw.GLProc = undefined;
    try gl.load(proc, glGetProcAddress);

    gl.viewport(0, 0, @intCast(width), @intCast(height));
    window.setFramebufferSizeCallback(frameBufferSizeCallback);

    gl.enable(gl.DEPTH_TEST);

    const lighting_shader = try learnopengl.Shader.init("shaders/16_4_light_casters.vs", "shaders/16_4_light_casters.fs");

    // set up vertex data and configure vertex attributes
    const vertices = [_]f32{
        // positions      // norms          // texture
        -0.5, -0.5, -0.5, 0.0,  0.0,  -1.0, 0.0, 0.0,
        0.5,  -0.5, -0.5, 0.0,  0.0,  -1.0, 1.0, 0.0,
        0.5,  0.5,  -0.5, 0.0,  0.0,  -1.0, 1.0, 1.0,
        0.5,  0.5,  -0.5, 0.0,  0.0,  -1.0, 1.0, 1.0,
        -0.5, 0.5,  -0.5, 0.0,  0.0,  -1.0, 0.0, 1.0,
        -0.5, -0.5, -0.5, 0.0,  0.0,  -1.0, 0.0, 0.0,

        -0.5, -0.5, 0.5,  0.0,  0.0,  1.0,  0.0, 0.0,
        0.5,  -0.5, 0.5,  0.0,  0.0,  1.0,  1.0, 0.0,
        0.5,  0.5,  0.5,  0.0,  0.0,  1.0,  1.0, 1.0,
        0.5,  0.5,  0.5,  0.0,  0.0,  1.0,  1.0, 1.0,
        -0.5, 0.5,  0.5,  0.0,  0.0,  1.0,  0.0, 1.0,
        -0.5, -0.5, 0.5,  0.0,  0.0,  1.0,  0.0, 0.0,

        -0.5, 0.5,  0.5,  -1.0, 0.0,  0.0,  0.0, 0.0,
        -0.5, 0.5,  -0.5, -1.0, 0.0,  0.0,  0.0, 0.0,
        -0.5, -0.5, -0.5, -1.0, 0.0,  0.0,  0.0, 0.0,
        -0.5, -0.5, -0.5, -1.0, 0.0,  0.0,  0.0, 0.0,
        -0.5, -0.5, 0.5,  -1.0, 0.0,  0.0,  0.0, 0.0,
        -0.5, 0.5,  0.5,  -1.0, 0.0,  0.0,  0.0, 0.0,

        0.5,  0.5,  0.5,  1.0,  0.0,  0.0,  1.0, 0.0,
        0.5,  0.5,  -0.5, 1.0,  0.0,  0.0,  1.0, 1.0,
        0.5,  -0.5, -0.5, 1.0,  0.0,  0.0,  0.0, 1.0,
        0.5,  -0.5, -0.5, 1.0,  0.0,  0.0,  0.0, 1.0,
        0.5,  -0.5, 0.5,  1.0,  0.0,  0.0,  0.0, 0.0,
        0.5,  0.5,  0.5,  1.0,  0.0,  0.0,  1.0, 0.0,

        -0.5, -0.5, -0.5, 0.0,  -1.0, 0.0,  1.0, 0.0,
        0.5,  -0.5, -0.5, 0.0,  -1.0, 0.0,  1.0, 1.0,
        0.5,  -0.5, 0.5,  0.0,  -1.0, 0.0,  0.0, 1.0,
        0.5,  -0.5, 0.5,  0.0,  -1.0, 0.0,  0.0, 1.0,
        -0.5, -0.5, 0.5,  0.0,  -1.0, 0.0,  0.0, 0.0,
        -0.5, -0.5, -0.5, 0.0,  -1.0, 0.0,  1.0, 0.0,

        -0.5, 0.5,  -0.5, 0.0,  1.0,  0.0,  0.0, 1.0,
        0.5,  0.5,  -0.5, 0.0,  1.0,  0.0,  1.0, 1.0,
        0.5,  0.5,  0.5,  0.0,  1.0,  0.0,  1.0, 0.0,
        0.5,  0.5,  0.5,  0.0,  1.0,  0.0,  1.0, 0.0,
        -0.5, 0.5,  0.5,  0.0,  1.0,  0.0,  0.0, 0.0,
        -0.5, 0.5,  -0.5, 0.0,  1.0,  0.0,  0.0, 1.0,
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

    gl.vertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 8 * @sizeOf(f32), null);
    gl.enableVertexAttribArray(0);
    const norm_offset: [*c]c_uint = (3 * @sizeOf(f32));
    gl.vertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 8 * @sizeOf(f32), norm_offset);
    gl.enableVertexAttribArray(1);
    const texture_offset: [*c]c_uint = (6 * @sizeOf(f32));
    gl.vertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, 8 * @sizeOf(f32), texture_offset);
    gl.enableVertexAttribArray(2);

    // light cube
    var light_cube_vao: c_uint = undefined;
    gl.genVertexArrays(1, &light_cube_vao);
    defer gl.deleteVertexArrays(1, &light_cube_vao);

    gl.bindVertexArray(light_cube_vao);
    gl.bindBuffer(gl.ARRAY_BUFFER, vbo);

    gl.vertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 8 * @sizeOf(f32), null);
    gl.enableVertexAttribArray(0);

    gl.bindBuffer(gl.ARRAY_BUFFER, 0);
    gl.bindVertexArray(0);

    const diffuse_map = loadTexture("images/container2.png");
    const specular_map = loadTexture("images/container2_specular.png");

    while (!window.shouldClose()) {
        processInput(window);

        gl.clearColor(0.2, 0.3, 0.3, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

        lighting_shader.use();
        lighting_shader.setFloat3("light.position", camera.position[0], camera.position[1], camera.position[2]);
        lighting_shader.setFloat3("light.direction", camera.front[0], camera.front[1], camera.front[2]);
        lighting_shader.setFloat("light.cutOff", @cos(to_radians(12.5)));
        lighting_shader.setFloat("light.outerCutOff", @cos(to_radians(17.5)));
        lighting_shader.setFloat3("viewPos", camera.position[0], camera.position[1], camera.position[2]);

        lighting_shader.setInt("material.diffuse", 0);
        lighting_shader.setInt("material.specular", 1);
        lighting_shader.setFloat("material.shininess", 32.0);

        lighting_shader.setFloat3("light.ambient", 0.2, 0.2, 0.2);
        lighting_shader.setFloat3("light.diffuse", 0.5, 0.5, 0.5);
        lighting_shader.setFloat3("light.specular", 1.0, 1.0, 1.0);

        const view = camera.getViewMatrix();
        var view_mat: [4 * 4]f32 = undefined;
        zmath.storeMat(&view_mat, view);
        lighting_shader.setFloatMatrix4("view", &view_mat);

        const projection = zmath.perspectiveFovRhGl(to_radians(camera.zoom), 800.0 / 600.0, 0.1, 100.0);
        var projection_mat: [4 * 4]f32 = undefined;
        zmath.storeMat(&projection_mat, projection);
        lighting_shader.setFloatMatrix4("projection", &projection_mat);

        gl.bindVertexArray(vao);

        gl.activeTexture(gl.TEXTURE0);
        gl.bindTexture(gl.TEXTURE_2D, diffuse_map);
        gl.activeTexture(gl.TEXTURE1);
        gl.bindTexture(gl.TEXTURE_2D, specular_map);

        for (cube_positions, 0..) |cube_position, i| {
            const translate = zmath.translation(cube_position[0], cube_position[1], cube_position[2]);

            const angle: f32 = 20.0 * @as(f32, @floatFromInt(i));
            const rotation = zmath.matFromAxisAngle(
                zmath.f32x4(1.0, 0.3, 0.5, 0.0),
                @floatCast(to_radians(angle)),
            );
            const model = zmath.mul(rotation, translate);
            var model_mat: [4 * 4]f32 = undefined;
            zmath.storeMat(&model_mat, model);
            lighting_shader.setFloatMatrix4("model", &model_mat);

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

fn mouseCallback(_: glfw.Window, xpos: f64, ypos: f64) void {
    if (first_mouse) {
        last_x = @floatCast(xpos);
        last_y = @floatCast(ypos);
        first_mouse = false;
    }
    const x_offset: f32 = @floatCast(xpos - last_x);
    const y_offset: f32 = @floatCast(last_y - ypos);

    last_x = @floatCast(xpos);
    last_y = @floatCast(ypos);

    camera.processMouseMovement(x_offset, y_offset, true);
}

fn scrollCallback(_: glfw.Window, _: f64, yoffset: f64) void {
    camera.processMouseScroll(@floatCast(yoffset));
}

fn processInput(window: glfw.Window) void {
    if (window.getKey(.escape) == .press) {
        window.setShouldClose(true);
    }

    const current_frame = @as(f32, @floatCast(glfw.getTime()));
    delta_time = current_frame - last_frame;
    last_frame = current_frame;
    if (window.getKey(.w) == .press) {
        camera.processKeyboard(.forward, delta_time);
    }
    if (window.getKey(.s) == .press) {
        camera.processKeyboard(.backward, delta_time);
    }
    if (window.getKey(.a) == .press) {
        camera.processKeyboard(.left, delta_time);
    }
    if (window.getKey(.d) == .press) {
        camera.processKeyboard(.right, delta_time);
    }
}

inline fn to_radians(angle: f32) f32 {
    return math.pi * angle / 180.0;
}

fn loadTexture(image_path: [*c]const u8) c_uint {
    var texture: c_uint = undefined;
    gl.genTextures(1, &texture);

    var image_width: c_int = undefined;
    var image_height: c_int = undefined;
    var nr_channels: c_int = undefined;
    const data = stbi.stbi_load(image_path, &image_width, &image_height, &nr_channels, 0);
    defer stbi.stbi_image_free(data);
    if (data != null) {
        var format: c_int = undefined;
        if (nr_channels == 1) {
            format = gl.RED;
        } else if (nr_channels == 3) {
            format = gl.RGB;
        } else if (nr_channels == 4) {
            format = gl.RGBA;
        } else {
            format = gl.RED;
        }

        gl.bindTexture(gl.TEXTURE_2D, texture);
        gl.texImage2D(gl.TEXTURE_2D, 0, format, image_width, image_height, 0, @intCast(format), gl.UNSIGNED_BYTE, data);
        gl.generateMipmap(gl.TEXTURE_2D);

        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
    } else {
        std.log.err("Failed to load texture", .{});
    }

    return texture;
}
