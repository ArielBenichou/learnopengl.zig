const std = @import("std");
const gl = @import("zopengl").bindings;
const VertexBuffer = @import("VertexBuffer.zig").VertexBuffer;

pub const VertexArray = struct {
    const Self = @This();

    id: gl.Uint,
    attributes_count: gl.Uint = 0,
    attributes_offset: usize = 0,

    pub fn init() Self {
        var id: gl.Uint = undefined;
        gl.genVertexArrays(1, &id);

        return Self{
            .id = id,
        };
    }

    pub fn addAttribute(
        self: *Self,
        vbo: VertexBuffer,
        size: gl.Int,
        attrib_type: gl.Enum,
        normalized: gl.Boolean,
    ) void {
        self.bind();
        defer self.unbind();
        vbo.bind();
        defer vbo.unbind();
        gl.vertexAttribPointer(
            self.attributes_count,
            size,
            attrib_type,
            normalized,
            vbo.stride * @sizeOf(gl.Float),
            @ptrFromInt(self.attributes_offset * @sizeOf(gl.Float)),
        );
        gl.enableVertexAttribArray(self.attributes_count);

        self.attributes_offset += @intCast(size);
        self.attributes_count += 1;
    }

    pub fn deinit(self: Self) void {
        gl.deleteVertexArrays(1, &self.id);
    }

    pub fn bind(self: Self) void {
        gl.bindVertexArray(self.id);
    }

    pub fn unbind(self: Self) void {
        _ = self;
        gl.bindVertexArray(0);
    }
};
