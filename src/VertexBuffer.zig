const std = @import("std");
const gl = @import("zopengl").bindings;

pub const VertexBuffer = struct {
    const Self = @This();

    id: gl.Uint,
    stride: gl.Sizei,

    pub const DrawMode = enum(comptime_int) {
        StaticDraw = gl.STATIC_DRAW,
        DynamicDraw = gl.DYNAMIC_DRAW,
    };

    pub fn init(data: []const gl.Float, stride: gl.Sizei, mode: DrawMode) Self {
        var id: gl.Uint = undefined;
        gl.genBuffers(1, &id);
        gl.bindBuffer(gl.ARRAY_BUFFER, id);
        gl.bufferData(
            gl.ARRAY_BUFFER,
            @intCast(@sizeOf(gl.Float) * data.len),
            data.ptr,
            @intFromEnum(mode),
        );
        // gl.bindBuffer(gl.ARRAY_BUFFER, 0);

        return Self{
            .id = id,
            .stride = stride,
        };
    }

    pub fn deinit(self: Self) void {
        gl.deleteBuffers(1, &self.id);
    }

    pub fn bind(self: Self) void {
        gl.bindBuffer(gl.ARRAY_BUFFER, self.id);
    }

    pub fn unbind(self: Self) void {
        _ = self;
        gl.bindBuffer(gl.ARRAY_BUFFER, 0);
    }
};
