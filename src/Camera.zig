const std = @import("std");

const zm = @import("zmath");

pub const Camera = struct {
    const Self = @This();

    position: zm.Vec = zm.loadArr3(.{ 0, 0, 7 }),
    front: zm.Vec = zm.loadArr3(.{ 0, 0, -1 }),
    world_up: zm.Vec = zm.loadArr3(.{ 0, 1, 0 }),
    up: zm.Vec = undefined,
    right: zm.Vec = undefined,

    yaw: f32 = -90,
    pitch: f32 = 0,

    movement_speed: f32 = 2.5,
    mouse_sensitivity: f32 = 0.1,
    zoom: f32 = 45,

    const CameraMovement = enum {
        Forward,
        Backward,
        Left,
        Right,
    };

    pub fn init(pos: zm.Vec, up: zm.Vec, yaw: f32, pitch: f32) Self {
        var camera = Self{
            .position = pos,
            .world_up = up,
            .yaw = yaw,
            .pitch = pitch,
        };
        camera.updateCameraVectors();
        return camera;
    }

    pub fn initDefault() Self {
        var camera = Self{};
        camera.updateCameraVectors();
        return camera;
    }

    pub fn getViewMatrix(self: Self) zm.Mat {
        return zm.lookAtRh(self.position, self.position + self.front, self.up);
    }

    pub fn processKeyboard(self: *Self, direction: CameraMovement, delta_time: f32) void {
        const velocity = zm.splat(zm.Vec, self.movement_speed * delta_time);
        switch (direction) {
            .Forward => {
                self.position += self.front * velocity;
            },
            .Backward => {
                self.position -= self.front * velocity;
            },
            .Left => {
                self.position -= self.right * velocity;
            },
            .Right => {
                self.position += self.right * velocity;
            },
        }
    }

    pub fn processMouseMovement(self: *Self, offset_x: f32, offset_y: f32, constrain_pitch: bool) void {
        self.yaw += offset_x * self.mouse_sensitivity;
        self.pitch += offset_y * self.mouse_sensitivity;
        if (constrain_pitch) {
            self.pitch = std.math.clamp(self.pitch, -89, 89);
        }

        self.updateCameraVectors();
    }

    pub fn processMouseScroll(self: *Self, offset_y: f32) void {
        self.zoom -= offset_y;
        self.zoom = std.math.clamp(self.zoom, 1, 45);
    }

    pub fn updateCameraVectors(self: *Self) void {
        self.front = zm.normalize3(
            zm.f32x4(
                @cos(std.math.degreesToRadians(self.yaw)) * @cos(std.math.degreesToRadians(self.pitch)),
                @sin(std.math.degreesToRadians(self.pitch)),
                @sin(std.math.degreesToRadians(self.yaw)) * @cos(std.math.degreesToRadians(self.pitch)),
                0,
            ),
        );

        self.right = zm.normalize3(zm.cross3(self.front, self.world_up));
        self.up = zm.normalize3(zm.cross3(self.right, self.front));
    }
};
