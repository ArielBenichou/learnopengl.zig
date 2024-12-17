const std = @import("std");
const gl = @import("zopengl").bindings;

pub const VertexBuffer = struct {
    const Self = @This();

    id: gl.Uint,
    stride: gl.Sizei,
    attributes_count: gl.Uint = 0,
    attributes_offset: usize = 0,

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

    pub fn addAttribute(
        self: *Self,
        size: gl.Int,
        attrib_type: gl.Enum,
        normalized: gl.Boolean,
    ) void {
        gl.vertexAttribPointer(
            self.attributes_count,
            size,
            attrib_type,
            normalized,
            self.stride * @sizeOf(gl.Float),
            @ptrFromInt(self.attributes_offset * @sizeOf(gl.Float)),
        );
        gl.enableVertexAttribArray(self.attributes_count);

        self.attributes_offset += @intCast(size);
        self.attributes_count += 1;
    }

    pub fn bind(self: Self) void {
        gl.bindBuffer(gl.ARRAY_BUFFER, self.id);
    }

    pub fn unbind() void {
        gl.bindBuffer(gl.ARRAY_BUFFER, 0);
    }
};
