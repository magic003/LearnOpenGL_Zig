const math = @import("std").math;
const zmath = @import("zmath");

pub const Camera = @This();

/// Defines the possible options of the camera movements.
pub const CameraMovement = enum {
    forward,
    backward,
    left,
    right,
};

const SPEED: f32 = 2.5;
const MOUSE_SENSITIVITY: f32 = 0.1;

// camera attributes
position: zmath.Vec,
front: zmath.Vec = undefined,
up: zmath.Vec = undefined,
right: zmath.Vec = undefined,
world_up: zmath.Vec,
yaw: f32,
pitch: f32,
zoom: f32 = 45.0,

/// Creates a new Camera instance.
pub fn init(position: zmath.Vec, world_up: zmath.Vec, yaw: f32, pitch: f32) Camera {
    var camera = Camera{
        .position = position,
        .world_up = world_up,
        .yaw = yaw,
        .pitch = pitch,
    };
    camera.updateCameraVectors();
    return camera;
}

/// returns the view matrix calculated using Euler Angles and the LookAt Matrix.
pub fn getViewMatrix(self: *Camera) zmath.Mat {
    return zmath.lookAtRh(self.position, self.position + self.front, self.up);
}

/// processes input received from any keyboard-like input system.
pub fn processKeyboard(self: *Camera, direction: CameraMovement, delta_time: f32) void {
    const velocity = zmath.f32x4s(SPEED * delta_time);
    switch (direction) {
        .forward => self.position += self.front * velocity,
        .backward => self.position -= self.front * velocity,
        .left => self.position -= self.right * velocity,
        .right => self.position += self.right * velocity,
    }
}
/// processes input received from a mouse input system. Expects the offset value in both the x and y direction.
pub fn processMouseMovement(self: *Camera, xoffset: f32, yoffset: f32, constraint_pitch: bool) void {
    self.yaw += xoffset * MOUSE_SENSITIVITY;
    self.pitch += yoffset * MOUSE_SENSITIVITY;

    if (constraint_pitch) {
        if (self.pitch > 89.0) {
            self.pitch = 89.0;
        }
        if (self.pitch < -89.0) {
            self.pitch = -89.0;
        }
    }

    self.updateCameraVectors();
}

/// processes input received from a mouse scroll-wheel event. Only requires input on the vertical wheel-axis.
pub fn processMouseScroll(self: *Camera, yoffset: f32) void {
    self.zoom -= yoffset;
    if (self.zoom < 1.0) {
        self.zoom = 1.0;
    }
    if (self.zoom > 45.0) {
        self.zoom = 45.0;
    }
}

/// Calculates the front vector from the Camera's (updated) Euler Angles.
fn updateCameraVectors(self: *Camera) void {
    const front_x = @cos(toRadians(self.yaw)) * @cos(toRadians(self.pitch));
    const front_y = @sin(toRadians(self.pitch));
    const front_z = @sin(toRadians(self.yaw)) * @cos(toRadians(self.pitch));

    self.front = zmath.normalize3(zmath.loadArr3(.{ front_x, front_y, front_z }));
    self.right = zmath.normalize3(zmath.cross3(self.front, self.world_up));
    self.up = zmath.normalize3(zmath.cross3(self.right, self.front));
}

inline fn toRadians(angle: f32) f32 {
    return math.pi * angle / 180.0;
}
