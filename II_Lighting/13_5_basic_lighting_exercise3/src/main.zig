const std = @import("std");
const math = std.math;
const glfw = @import("mach-glfw");
const gl = @import("gl");
const learnopengl = @import("learnopengl");
const zmath = @import("zmath");

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

const light_pos = zmath.loadArr3(.{ 1.2, 1.0, 2.0 });

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

    const lighting_shader = try learnopengl.Shader.init("shaders/13_5_basic_lighting.vs", "shaders/13_5_basic_lighting.fs");
    const light_cube_shader = try learnopengl.Shader.init("shaders/13_5_light_cube.vs", "shaders/13_5_light_cube.fs");

    // set up vertex data and configure vertex attributes
    const vertices = [_]f32{
        // positions      // norms
        -0.5, -0.5, -0.5, 0.0,  0.0,  -1.0,
        0.5,  -0.5, -0.5, 0.0,  0.0,  -1.0,
        0.5,  0.5,  -0.5, 0.0,  0.0,  -1.0,
        0.5,  0.5,  -0.5, 0.0,  0.0,  -1.0,
        -0.5, 0.5,  -0.5, 0.0,  0.0,  -1.0,
        -0.5, -0.5, -0.5, 0.0,  0.0,  -1.0,

        -0.5, -0.5, 0.5,  0.0,  0.0,  1.0,
        0.5,  -0.5, 0.5,  0.0,  0.0,  1.0,
        0.5,  0.5,  0.5,  0.0,  0.0,  1.0,
        0.5,  0.5,  0.5,  0.0,  0.0,  1.0,
        -0.5, 0.5,  0.5,  0.0,  0.0,  1.0,
        -0.5, -0.5, 0.5,  0.0,  0.0,  1.0,

        -0.5, 0.5,  0.5,  -1.0, 0.0,  0.0,
        -0.5, 0.5,  -0.5, -1.0, 0.0,  0.0,
        -0.5, -0.5, -0.5, -1.0, 0.0,  0.0,
        -0.5, -0.5, -0.5, -1.0, 0.0,  0.0,
        -0.5, -0.5, 0.5,  -1.0, 0.0,  0.0,
        -0.5, 0.5,  0.5,  -1.0, 0.0,  0.0,

        0.5,  0.5,  0.5,  1.0,  0.0,  0.0,
        0.5,  0.5,  -0.5, 1.0,  0.0,  0.0,
        0.5,  -0.5, -0.5, 1.0,  0.0,  0.0,
        0.5,  -0.5, -0.5, 1.0,  0.0,  0.0,
        0.5,  -0.5, 0.5,  1.0,  0.0,  0.0,
        0.5,  0.5,  0.5,  1.0,  0.0,  0.0,

        -0.5, -0.5, -0.5, 0.0,  -1.0, 0.0,
        0.5,  -0.5, -0.5, 0.0,  -1.0, 0.0,
        0.5,  -0.5, 0.5,  0.0,  -1.0, 0.0,
        0.5,  -0.5, 0.5,  0.0,  -1.0, 0.0,
        -0.5, -0.5, 0.5,  0.0,  -1.0, 0.0,
        -0.5, -0.5, -0.5, 0.0,  -1.0, 0.0,

        -0.5, 0.5,  -0.5, 0.0,  1.0,  0.0,
        0.5,  0.5,  -0.5, 0.0,  1.0,  0.0,
        0.5,  0.5,  0.5,  0.0,  1.0,  0.0,
        0.5,  0.5,  0.5,  0.0,  1.0,  0.0,
        -0.5, 0.5,  0.5,  0.0,  1.0,  0.0,
        -0.5, 0.5,  -0.5, 0.0,  1.0,  0.0,
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

    gl.vertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 6 * @sizeOf(f32), null);
    gl.enableVertexAttribArray(0);
    const norm_offset: [*c]c_uint = (3 * @sizeOf(f32));
    gl.vertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 6 * @sizeOf(f32), norm_offset);
    gl.enableVertexAttribArray(1);

    // light cube
    var light_cube_vao: c_uint = undefined;
    gl.genVertexArrays(1, &light_cube_vao);
    defer gl.deleteVertexArrays(1, &light_cube_vao);

    gl.bindVertexArray(light_cube_vao);
    gl.bindBuffer(gl.ARRAY_BUFFER, vbo);

    gl.vertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 6 * @sizeOf(f32), null);
    gl.enableVertexAttribArray(0);

    gl.bindBuffer(gl.ARRAY_BUFFER, 0);
    gl.bindVertexArray(0);

    while (!window.shouldClose()) {
        processInput(window);

        gl.clearColor(0.2, 0.3, 0.3, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

        lighting_shader.use();
        lighting_shader.setFloat3("objectColor", 1.0, 0.5, 0.31);
        lighting_shader.setFloat3("lightColor", 1.01, 1.01, 1.0);
        lighting_shader.setFloat3("lightPos", light_pos[0], light_pos[1], light_pos[2]);
        lighting_shader.setFloat3("viewPos", camera.position[0], camera.position[1], camera.position[2]);

        const model = zmath.identity();
        var model_mat: [4 * 4]f32 = undefined;
        zmath.storeMat(&model_mat, model);
        lighting_shader.setFloatMatrix4("model", &model_mat);

        const view = camera.getViewMatrix();
        var view_mat: [4 * 4]f32 = undefined;
        zmath.storeMat(&view_mat, view);
        lighting_shader.setFloatMatrix4("view", &view_mat);

        const projection = zmath.perspectiveFovRhGl(to_radians(camera.zoom), 800.0 / 600.0, 0.1, 100.0);
        var projection_mat: [4 * 4]f32 = undefined;
        zmath.storeMat(&projection_mat, projection);
        lighting_shader.setFloatMatrix4("projection", &projection_mat);

        gl.bindVertexArray(vao);
        gl.drawArrays(gl.TRIANGLES, 0, 36);

        // light cube
        light_cube_shader.use();

        const translate = zmath.translationV(light_pos);
        const light_cube_model = zmath.mul(zmath.scaling(0.2, 0.2, 0.2), translate);
        var light_cube_model_mat: [4 * 4]f32 = undefined;
        zmath.storeMat(&light_cube_model_mat, light_cube_model);
        const light_cube_model_loc = gl.getUniformLocation(light_cube_shader.ID, "model");
        gl.uniformMatrix4fv(light_cube_model_loc, 1, gl.FALSE, &light_cube_model_mat);

        const light_cube_view_loc = gl.getUniformLocation(light_cube_shader.ID, "view");
        gl.uniformMatrix4fv(light_cube_view_loc, 1, gl.FALSE, &view_mat);

        const light_cube_projection_loc = gl.getUniformLocation(light_cube_shader.ID, "projection");
        gl.uniformMatrix4fv(light_cube_projection_loc, 1, gl.FALSE, &projection_mat);

        gl.bindVertexArray(light_cube_vao);
        gl.drawArrays(gl.TRIANGLES, 0, 36);

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
