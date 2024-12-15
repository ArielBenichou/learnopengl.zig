const std = @import("std");
const builtin = @import("builtin");
const glfw = @import("zglfw");
const zopengl = @import("zopengl");
const zstbi = @import("zstbi");
const gl = zopengl.bindings;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(gpa.deinit() == .ok);

    zstbi.init(allocator);
    defer zstbi.deinit();

    try glfw.init();
    defer glfw.terminate();

    const gl_major = 3;
    const gl_minor = 3;
    glfw.windowHintTyped(.context_version_major, gl_major);
    glfw.windowHintTyped(.context_version_minor, gl_minor);
    glfw.windowHintTyped(.opengl_profile, .opengl_core_profile);
    if (builtin.target.os.tag.isDarwin()) {
        glfw.windowHintTyped(.opengl_forward_compat, true);
    }
    glfw.windowHintTyped(.client_api, .opengl_api);
    glfw.windowHintTyped(.doublebuffer, true);

    const window = glfw.Window.create(
        initial_screen_size.width,
        initial_screen_size.height,
        "LearnOpenGL",
        null,
    ) catch {
        glfw.terminate();
        std.process.exit(1);
    };
    defer window.destroy();

    glfw.makeContextCurrent(window);

    try zopengl.loadCoreProfile(
        glfw.getProcAddress,
        gl_major,
        gl_minor,
    );

    gl.viewport(
        0,
        0,
        initial_screen_size.width,
        initial_screen_size.height,
    );
    _ = window.setFramebufferSizeCallback(framebufferSizeCallback);

    const shader_vertex = try createShader(
        shader_vertex_source,
        gl.VERTEX_SHADER,
        "VERTEX",
    );
    const shader_fragment = try createShader(
        shader_fragment_source,
        gl.FRAGMENT_SHADER,
        "FRAGMENT",
    );
    const shader_program = try createProgram(
        shader_vertex,
        shader_fragment,
    );

    // zig fmt: off
    const vertices = [_]gl.Float {
        // positions       // colors        // texture coords
         0.5,  0.5, 0.0,   1.0, 0.0, 0.0,   1.0, 1.0,   // top right
         0.5, -0.5, 0.0,   0.0, 1.0, 0.0,   1.0, 0.0,   // bottom right
        -0.5, -0.5, 0.0,   0.0, 0.0, 1.0,   0.0, 0.0,   // bottom let
        -0.5,  0.5, 0.0,   1.0, 1.0, 0.0,   0.0, 1.0    // top let 
    };
    // zig fmt: on

    var vao: gl.Uint = undefined;
    gl.genVertexArrays(1, &vao);
    gl.bindVertexArray(vao);

    var vbo: gl.Uint = undefined;
    gl.genBuffers(1, &vbo);
    gl.bindBuffer(gl.ARRAY_BUFFER, vbo);
    gl.bufferData(
        gl.ARRAY_BUFFER,
        @sizeOf(@TypeOf(vertices)),
        &vertices,
        gl.STATIC_DRAW,
    );

    gl.vertexAttribPointer(
        0,
        3,
        gl.FLOAT,
        gl.FALSE,
        3 * @sizeOf(gl.Float),
        @ptrFromInt(0),
    );
    gl.enableVertexAttribArray(0);

    var texture: gl.Uint = undefined;
    gl.genTextures(1, &texture);
    gl.bindTexture(gl.TEXTURE_2D, texture);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);

    var image = try zstbi.Image.loadFromFile("assets/container.jpg", 0);
    defer image.deinit();
    gl.texImage2D(
        gl.TEXTURE_2D,
        0,
        gl.RGB,
        @as(gl.Int, @intCast(image.width)),
        @as(gl.Int, @intCast(image.height)),
        0,
        gl.RGB,
        gl.UNSIGNED_BYTE,
        @ptrCast(image.data),
    );
    gl.generateMipmap(gl.TEXTURE_2D);

    glfw.swapInterval(1); // WHY?
    while (!window.shouldClose()) {
        glfw.pollEvents();
        processInput(window);

        gl.clearColor(0.2, 0.3, 0.3, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT);

        gl.useProgram(shader_program);
        gl.bindVertexArray(vao);
        gl.drawArrays(gl.TRIANGLES, 0, 3);

        window.swapBuffers();
    }
}
const initial_screen_size = .{
    .width = 800,
    .height = 600,
};

const shader_vertex_source = @embedFile("./shaders/default.vert.glsl");

const shader_fragment_source = @embedFile("./shaders/default.frag.glsl");

fn createShader(source: [:0]const u8, shader_type: gl.Enum, name: [:0]const u8) !gl.Uint {
    const shader = gl.createShader(shader_type);
    gl.shaderSource(
        shader,
        1,
        @alignCast(@ptrCast(&source)),
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
        std.debug.print("[OPENGL] INFO::SHADER::{s}::COMPILATION_SUCCESS\n{s}\n", .{ name, info_log[0..i] });
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
        std.debug.print("[OPENGL] INFO::SHADER::PROGRAM::LINKING_SUCCESS\n{s}\n", .{info_log[0..i]});
    }

    return program;
}

fn framebufferSizeCallback(window: *glfw.Window, width: i32, height: i32) callconv(.c) void {
    _ = window;
    gl.viewport(
        0,
        0,
        width,
        height,
    );
}

fn processInput(window: *glfw.Window) callconv(.c) void {
    if (window.getKey(.escape) == .press) {
        window.setShouldClose(true);
    }
}
