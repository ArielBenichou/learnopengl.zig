const std = @import("std");
const gl = @import("zopengl").bindings;

pub const VertexArray = struct {
    const Self = @This();

    id: gl.Uint,

    pub fn init() Self {
        var id: gl.Uint = undefined;
        gl.genVertexArrays(1, &id);

        return Self{
            .id = id,
        };
    }

    pub fn deinit(self: Self) void {
        gl.deleteVertexArrays(1, &self.id);
    }

    pub fn bind(self: Self) void {
        gl.bindVertexArray(self.id);
    }

    pub fn unbind() void {
        gl.bindVertexArray(0);
    }
};
