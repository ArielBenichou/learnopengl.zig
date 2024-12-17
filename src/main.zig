const std = @import("std");
const builtin = @import("builtin");
const glfw = @import("zglfw");
const zopengl = @import("zopengl");
const zstbi = @import("zstbi");
const gl = zopengl.bindings;
const Shader = @import("Shader.zig").Shader;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
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

    const shader = try Shader.init(
        allocator,
        "./src/shaders/default.vert.glsl",
        "./src/shaders/default.frag.glsl",
    );
    defer shader.deinit();

    // zig fmt: off
    const vertices = [_]gl.Float {
        // positions       // colors        // texture coords
         0.5,  0.5, 0.0,   1.0, 0.0, 0.0,   1.0, 1.0,   // top right
         0.5, -0.5, 0.0,   0.0, 1.0, 0.0,   1.0, 0.0,   // bottom right
        -0.5, -0.5, 0.0,   0.0, 0.0, 1.0,   0.0, 0.0,   // bottom let
        -0.5,  0.5, 0.0,   1.0, 1.0, 0.0,   0.0, 1.0    // top let 
    };

    const indices = [_]gl.Float{
        0, 1, 3,
        1, 2, 3,
    };
    // zig fmt: on

    var vao: gl.Uint = undefined;
    gl.genVertexArrays(1, &vao);
    defer gl.deleteVertexArrays(1, &vao);
    gl.bindVertexArray(vao);

    var vbo: gl.Uint = undefined;
    gl.genBuffers(1, &vbo);
    defer gl.deleteBuffers(1, &vbo);
    gl.bindBuffer(gl.ARRAY_BUFFER, vbo);
    gl.bufferData(
        gl.ARRAY_BUFFER,
        @sizeOf(@TypeOf(vertices)),
        &vertices,
        gl.STATIC_DRAW,
    );

    var ebo: gl.Uint = undefined;
    gl.genBuffers(1, &ebo);
    defer gl.deleteBuffers(1, &ebo);
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo);
    gl.bufferData(
        gl.ELEMENT_ARRAY_BUFFER,
        @sizeOf(@TypeOf(indices)),
        &indices,
        gl.STATIC_DRAW,
    );

    // pos attrib
    gl.vertexAttribPointer(
        0,
        3,
        gl.FLOAT,
        gl.FALSE,
        8 * @sizeOf(gl.Float),
        @ptrFromInt(0),
    );
    gl.enableVertexAttribArray(0);

    // color attrib
    gl.vertexAttribPointer(
        1,
        3,
        gl.FLOAT,
        gl.FALSE,
        8 * @sizeOf(gl.Float),
        @ptrFromInt(3 * @sizeOf(gl.Float)),
    );
    gl.enableVertexAttribArray(1);

    // texcoord attrib
    gl.vertexAttribPointer(
        2,
        2,
        gl.FLOAT,
        gl.FALSE,
        8 * @sizeOf(gl.Float),
        @ptrFromInt(6 * @sizeOf(gl.Float)),
    );
    gl.enableVertexAttribArray(1);

    var texture: gl.Uint = undefined;
    gl.genTextures(1, &texture);
    gl.bindTexture(gl.TEXTURE_2D, texture);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);

    {
        var image = try zstbi.Image.loadFromFile(
            "assets/container.jpg",
            0,
        );
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
    }

    shader.use();
    shader.setInt("tex", 0);

    glfw.swapInterval(1); // WHY?
    while (!window.shouldClose()) {
        processInput(window);

        gl.clearColor(0.2, 0.3, 0.3, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT);

        gl.activeTexture(gl.TEXTURE0);
        gl.bindTexture(gl.TEXTURE_2D, texture);

        gl.bindVertexArray(vao);
        gl.drawElements(
            gl.TRIANGLES,
            6,
            gl.UNSIGNED_INT,
            @ptrFromInt(0),
        );

        window.swapBuffers();
        glfw.pollEvents();
    }
}

const initial_screen_size = .{
    .width = 800,
    .height = 600,
};

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
