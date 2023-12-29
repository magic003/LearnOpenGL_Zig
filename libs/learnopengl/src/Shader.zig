const std = @import("std");
const gl = @import("gl");

pub const Shader = @This();

/// The shader program ID.
ID: c_uint,

/// Creates a Sharder by providing the vertex and fragment shader paths.
pub fn init(vertex_path: []const u8, fragment_path: []const u8) !Shader {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const exe_dir = try std.fs.selfExeDirPathAlloc(allocator);
    const vertex_abs_path = try std.fs.path.join(allocator, &.{ exe_dir, vertex_path });
    const vertex_file = try std.fs.openFileAbsolute(vertex_abs_path, .{});
    defer vertex_file.close();
    const vertext_code = try vertex_file.readToEndAllocOptions(allocator, 3 * 1024, null, @alignOf(u8), 0);

    const fragment_abs_path = try std.fs.path.join(allocator, &.{ exe_dir, fragment_path });
    const fragment_file = try std.fs.openFileAbsolute(fragment_abs_path, .{});
    defer fragment_file.close();
    const fragment_code = try fragment_file.readToEndAllocOptions(allocator, 3 * 1024, null, @alignOf(u8), 0);

    const vertex_shader = gl.createShader(gl.VERTEX_SHADER);
    gl.shaderSource(vertex_shader, 1, @ptrCast(&vertext_code), null);
    gl.compileShader(vertex_shader);
    var success = [_]c_int{0};
    var info_log: [512]u8 = undefined;
    gl.getShaderiv(vertex_shader, gl.COMPILE_STATUS, &success);
    if (success[0] == 0) {
        gl.getShaderInfoLog(vertex_shader, 512, null, &info_log);
        std.log.err("Vertext shader compilation failed: {s}", .{info_log});
    }

    const fragment_shader = gl.createShader(gl.FRAGMENT_SHADER);
    gl.shaderSource(fragment_shader, 1, @ptrCast(&fragment_code), null);
    gl.compileShader(fragment_shader);
    gl.getShaderiv(fragment_shader, gl.COMPILE_STATUS, &success);
    if (success[0] == 0) {
        gl.getShaderInfoLog(fragment_shader, 512, null, &info_log);
        std.log.err("Fragment shader compilation failed: {s}", .{info_log});
    }

    const shader_program = gl.createProgram();
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

    return Shader{ .ID = shader_program };
}

/// Uses the shader program.
pub fn use(self: Shader) void {
    gl.useProgram(self.ID);
}

// Sets the uniform bool value.
pub fn setBool(self: Shader, name: [:0]const u8, value: bool) void {
    gl.uniform1i(gl.getUniformLocation(self.ID, &name.*), @intFromBool(value));
}

// Sets the uniform int value.
pub fn setInt(self: Shader, name: [:0]const u8, value: u32) void {
    gl.uniform1i(gl.getUniformLocation(self.ID, &name.*), @intCast(value));
}

// Sets the uniform float value.
pub fn setFloat(self: Shader, name: [:0]const u8, value: f32) void {
    gl.uniform1f(gl.getUniformLocation(self.ID, &name.*), value);
}
