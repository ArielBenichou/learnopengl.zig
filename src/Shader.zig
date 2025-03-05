const std = @import("std");
const zm = @import("zmath");
const gl = @import("zopengl").bindings;

pub const Shader = struct {
    const Self = @This();

    id: gl.Uint,

    pub fn init(allocator: std.mem.Allocator, vertex_path: []const u8, fragment_path: []const u8) !Self {
        const vertex_source = try std.fs.cwd().readFileAlloc(
            allocator,
            vertex_path,
            1024,
        );
        defer allocator.free(vertex_source);
        const vertex_source_z = try allocator.dupeZ(u8, vertex_source);
        defer allocator.free(vertex_source_z);

        const fragment_source = try std.fs.cwd().readFileAlloc(
            allocator,
            fragment_path,
            1024,
        );
        defer allocator.free(fragment_source);
        const fragment_source_z = try allocator.dupeZ(u8, fragment_source);
        defer allocator.free(fragment_source_z);

        const vertex = try Self.createShader(
            vertex_source_z,
            gl.VERTEX_SHADER,
            "VERTEX",
        );
        defer gl.deleteShader(vertex);

        const fragment = try Self.createShader(
            fragment_source_z,
            gl.FRAGMENT_SHADER,
            "FRAGMENT",
        );
        defer gl.deleteShader(fragment);

        const program = try Self.createProgram(
            vertex,
            fragment,
        );

        return .{
            .id = program,
        };
    }

    pub fn deinit(self: Self) void {
        gl.deleteProgram(self.id);
    }

    pub fn use(self: Self) void {
        gl.useProgram(self.id);
    }

    pub fn setBool(self: Self, name: []const u8, value: gl.Boolean) void {
        gl.uniform1i(
            gl.getUniformLocation(self.id, name.ptr),
            @intFromBool(value),
        );
    }
    pub fn setInt(self: Self, name: []const u8, value: gl.Int) void {
        gl.uniform1i(
            gl.getUniformLocation(self.id, name.ptr),
            value,
        );
    }
    pub fn setFloat(self: Self, name: []const u8, value: gl.Float) void {
        gl.uniform1f(
            gl.getUniformLocation(self.id, name.ptr),
            value,
        );
    }
    pub fn setMat(self: Self, name: []const u8, value: [16]f32) void {
        gl.uniformMatrix4fv(
            gl.getUniformLocation(self.id, name.ptr),
            1,
            gl.FALSE,
            &value,
        );
    }

    fn createShader(source: [:0]const u8, shader_type: gl.Enum, name: []const u8) !gl.Uint {
        const shader = gl.createShader(shader_type);
        gl.shaderSource(
            shader,
            1,
            &[_][*c]const u8{source.ptr},
            null,
        );
        gl.compileShader(shader);

        var success: gl.Int = undefined;
        gl.getShaderiv(shader, gl.COMPILE_STATUS, &success);
        var info_log: [512]u8 = undefined;
        var log_size: gl.Int = 0;
        gl.getShaderInfoLog(
            shader,
            512,
            &log_size,
            @constCast(&info_log),
        );
        const i: usize = @intCast(log_size);
        if (success == 0) {
            std.debug.print("[OPENGL] ERROR::SHADER::{s}::COMPILATION_FAILED\n{s}\n", .{ name, info_log[0..i] });
            return error.LinkingFailed;
        } else {
            std.debug.print("[OPENGL] INFO::SHADER::{s}::COMPILATION_SUCCESS {s}\n", .{ name, info_log[0..i] });
        }

        return shader;
    }

    fn createProgram(shader_vertex: gl.Uint, shader_fragment: gl.Uint) !gl.Uint {
        const program = gl.createProgram();
        gl.attachShader(program, shader_vertex);
        gl.attachShader(program, shader_fragment);
        gl.linkProgram(program);
        gl.deleteShader(shader_vertex);
        gl.deleteShader(shader_fragment);

        var success: gl.Int = undefined;
        gl.getProgramiv(program, gl.LINK_STATUS, &success);
        var info_log: [512]u8 = undefined;
        var log_size: gl.Int = 0;
        gl.getProgramInfoLog(
            program,
            512,
            &log_size,
            @constCast(&info_log),
        );
        const i: usize = @intCast(log_size);
        if (success == 0) {
            std.debug.print("[OPENGL] ERROR::SHADER::PROGRAM::LINKING_FAILED\n{s}\n", .{info_log[0..i]});
            return error.CompilationFailed;
        } else {
            std.debug.print("[OPENGL] INFO::SHADER::PROGRAM::LINKING_SUCCESS {s}\n", .{info_log[0..i]});
        }

        return program;
    }
};
