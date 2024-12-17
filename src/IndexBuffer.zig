const std = @import("std");
const gl = @import("zopengl").bindings;

pub const IndexBuffer = struct {
    const Self = @This();

    id: gl.Uint,
    count: gl.Sizei,

    pub const DrawMode = enum(comptime_int) {
        StaticDraw = gl.STATIC_DRAW,
        DynamicDraw = gl.DYNAMIC_DRAW,
    };

    pub fn init(data: []const gl.Uint, mode: DrawMode) Self {
        var id: gl.Uint = undefined;
        gl.genBuffers(1, &id);
        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, id);
        gl.bufferData(
            gl.ELEMENT_ARRAY_BUFFER,
            @intCast(@sizeOf(gl.Uint) * data.len),
            data.ptr,
            @intFromEnum(mode),
        );
        // gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0);

        return Self{
            .id = id,
            .count = @intCast(data.len),
        };
    }

    pub fn deinit(self: Self) void {
        gl.deleteBuffers(1, &self.id);
    }

    pub fn bind(self: Self) void {
        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, self.id);
    }

    pub fn unbind() void {
        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0);
    }
};
