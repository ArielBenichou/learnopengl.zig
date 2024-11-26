const std = @import("std");
const builtin = @import("builtin");
const glfw = @import("zglfw");
const zopengl = @import("zopengl");
const gl = zopengl.bindings;

const State = struct {
    is_wireframe: bool,
};
var state: State = .{
    .is_wireframe = false,
};

pub fn main() !void {
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
    const shader_fragment_orange = try createShader(
        shader_fragment_orange_source,
        gl.FRAGMENT_SHADER,
        "FRAGMENT",
    );

    const triangle_orange_program = try createProgram(
        shader_vertex,
        shader_fragment_orange,
    );
    defer gl.deleteProgram(triangle_orange_program);

    const shader_fragment_yellow = try createShader(
        shader_fragment_yellow_source,
        gl.FRAGMENT_SHADER,
        "FRAGMENT",
    );
    const triangle_yellow_program = try createProgram(
        shader_vertex,
        shader_fragment_yellow,
    );
    defer gl.deleteProgram(triangle_yellow_program);

    // zig fmt: off
    // TWO TRIANGLES
    const triangle_orange = [_]gl.Float{ 
        -0.4, 0.0, 0.0,
        -0.25, 0.3, 0.0,
        -0.1, 0.0, 0.0,
    };

    const triangle_yellow = [_]gl.Float{ 
        0.4, 0.0, 0.0,
        0.25, 0.3, 0.0,
        0.1, 0.0, 0.0,
    };
    // zig fmt: on

    var triangle_orange_vao: gl.Uint = undefined;
    gl.genVertexArrays(1, &triangle_orange_vao);
    defer gl.deleteVertexArrays(1, &triangle_orange_vao);
    gl.bindVertexArray(triangle_orange_vao);

    var triangle_orange_vbo: gl.Uint = undefined;
    gl.genBuffers(1, &triangle_orange_vbo);
    defer gl.deleteBuffers(1, &triangle_orange_vbo);
    gl.bindBuffer(gl.ARRAY_BUFFER, triangle_orange_vbo);
    gl.bufferData(
        gl.ARRAY_BUFFER,
        @sizeOf(@TypeOf(triangle_orange)),
        &triangle_orange,
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

    var triangle_yellow_vao: gl.Uint = undefined;
    gl.genVertexArrays(1, &triangle_yellow_vao);
    defer gl.deleteVertexArrays(1, &triangle_yellow_vao);
    gl.bindVertexArray(triangle_yellow_vao);

    var triangle_yellow_vbo: gl.Uint = undefined;
    gl.genBuffers(1, &triangle_yellow_vbo);
    defer gl.deleteBuffers(1, &triangle_yellow_vbo);
    gl.bindBuffer(gl.ARRAY_BUFFER, triangle_yellow_vbo);
    gl.bufferData(
        gl.ARRAY_BUFFER,
        @sizeOf(@TypeOf(triangle_yellow)),
        &triangle_yellow,
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

    glfw.swapInterval(1); // WHY?
    while (!window.shouldClose()) {
        glfw.pollEvents();
        processInput(window);

        gl.clearColor(0.2, 0.3, 0.3, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT);

        if (state.is_wireframe) {
            gl.polygonMode(gl.FRONT_AND_BACK, gl.LINE);
        } else {
            gl.polygonMode(gl.FRONT_AND_BACK, gl.FILL);
        }

        gl.useProgram(triangle_orange_program);
        gl.bindVertexArray(triangle_orange_vao);
        gl.drawArrays(gl.TRIANGLES, 0, 3);

        gl.useProgram(triangle_yellow_program);
        gl.bindVertexArray(triangle_yellow_vao);
        gl.drawArrays(gl.TRIANGLES, 0, 3);

        window.swapBuffers();
    }
}

//--------------------------
//--------------------------
//--------------------------
const initial_screen_size = .{
    .width = 800,
    .height = 600,
};

const shader_vertex_source =
    \\ #version 330 core
    \\ layout (location = 0) in vec3 aPos;
    \\ void main()
    \\ {
    \\   gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
    \\ }
;

const shader_fragment_orange_source =
    \\ #version 330 core
    \\ out vec4 FragColor;
    \\
    \\ void main() {
    \\  FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
    \\ }
;

const shader_fragment_yellow_source =
    \\ #version 330 core
    \\ out vec4 FragColor;
    \\
    \\ void main() {
    \\  FragColor = vec4(1.0f, 1.0f, 0.0f, 1.0f);
    \\ }
;

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

    if (window.getKey(.w) == .press) {
        // TODO: create a key DOWN event
        state.is_wireframe = !state.is_wireframe;
    }
}
