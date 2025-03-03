const builtin = @import("builtin");
const std = @import("std");
const glfw = @import("zglfw");
const zopengl = @import("zopengl");
const zstbi = @import("zstbi");
const zm = @import("zmath");
const gl = zopengl.bindings;
const Shader = @import("Shader.zig").Shader;
const VertexArray = @import("VertexArray.zig").VertexArray;
const VertexBuffer = @import("VertexBuffer.zig").VertexBuffer;
const IndexBuffer = @import("IndexBuffer.zig").IndexBuffer;
const Texture2D = @import("Texture2D.zig").Texture2D;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    defer std.debug.assert(gpa.deinit() == .ok);

    zstbi.init(allocator);
    zstbi.setFlipVerticallyOnLoad(true);
    defer zstbi.deinit();

    try glfw.init();
    defer glfw.terminate();

    const gl_major = 3;
    const gl_minor = 3;
    glfw.windowHint(.context_version_major, gl_major);
    glfw.windowHint(.context_version_minor, gl_minor);
    glfw.windowHint(.opengl_profile, .opengl_core_profile);
    if (builtin.target.os.tag.isDarwin()) {
        glfw.windowHint(.opengl_forward_compat, true);
    }
    glfw.windowHint(.client_api, .opengl_api);
    glfw.windowHint(.doublebuffer, true);

    const window = glfw.Window.create(
        screen_size.width,
        screen_size.height,
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
        screen_size.width,
        screen_size.height,
    );
    _ = window.setFramebufferCallback(framebufferSizeCallback);

    const shader = try Shader.init(
        allocator,
        "./src/shaders/default.vert.glsl",
        "./src/shaders/default.frag.glsl",
    );
    defer shader.deinit();

    // zig fmt: off
    const vertices = [_]gl.Float {
        // positions  // colors        // texture coords
         5,  5, 0,     1.0, 0.0, 0.0,   1.0, 1.0,   // top right
         5, -5, 0,     0.0, 1.0, 0.0,   1.0, 0.0,   // bottom right
        -5, -5, 0,     0.0, 0.0, 1.0,   0.0, 0.0,   // bottom let
        -5,  5, 0,     1.0, 1.0, 0.0,   0.0, 1.0,   // top let 
    };

    const indices = [_]gl.Uint{
        0, 1, 3,
        1, 2, 3,
    };
    // zig fmt: on

    const rect_vao = VertexArray.init();
    defer rect_vao.deinit();
    rect_vao.bind();

    var rect_vbo = VertexBuffer.init(&vertices, 8, .StaticDraw);
    defer rect_vbo.deinit();
    rect_vbo.bind();

    // pos attrib
    rect_vbo.addAttribute(3, gl.FLOAT, gl.FALSE);
    // color attrib
    rect_vbo.addAttribute(3, gl.FLOAT, gl.FALSE);
    // texcoord attrib
    rect_vbo.addAttribute(2, gl.FLOAT, gl.FALSE);

    const rect_ebo = IndexBuffer.init(&indices, .StaticDraw);
    defer rect_ebo.deinit();
    rect_ebo.bind();

    const crate_tex = tex: {
        var image = try zstbi.Image.loadFromFile(
            "assets/container.jpg",
            0,
        );
        defer image.deinit();
        break :tex Texture2D.init(
            image.data,
            image.width,
            image.height,
            .RGB,
        );
    };
    defer crate_tex.deinit();

    const face_tex = tex: {
        var image = try zstbi.Image.loadFromFile(
            "assets/awesomeface.png",
            0,
        );
        defer image.deinit();
        break :tex Texture2D.init(
            image.data,
            image.width,
            image.height,
            .RGBA,
        );
    };
    defer face_tex.deinit();

    shader.use();
    shader.setInt("base_tex", 0);
    shader.setInt("overlay_tex", 1);

    glfw.swapInterval(1);

    while (!window.shouldClose()) {
        // UPDATE
        const aspect_ratio = @as(f32, @floatFromInt(screen_size.width)) / @as(f32, @floatFromInt(screen_size.height));
        const projection = zm.orthographicLhGl(
            WORLD_SPACE_SIZE * aspect_ratio,
            WORLD_SPACE_SIZE,
            0.1,
            WORLD_SPACE_SIZE,
        );
        const view = zm.mul(zm.translation(0, 0, 0), zm.rotationZ(std.math.degreesToRadians(45)));
        const model = zm.mul(zm.translation(0, 0, 0), zm.rotationZ(std.math.degreesToRadians(0)));
        const mvp = zm.mul(zm.mul(projection, view), model);
        shader.setMat("mvp", &mvp);

        processInput(window);

        // DRAW
        gl.clearColor(0.2, 0.3, 0.3, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT);

        gl.activeTexture(gl.TEXTURE0);
        crate_tex.bind();
        gl.activeTexture(gl.TEXTURE1);
        face_tex.bind();

        rect_vao.bind();
        gl.drawElements(
            gl.TRIANGLES,
            rect_ebo.count,
            gl.UNSIGNED_INT,
            @ptrFromInt(0),
        );

        window.swapBuffers();
        glfw.pollEvents();
    }
}

const ScreenSize = struct {
    width: gl.Sizei = 800,
    height: gl.Sizei = 600,
};
var screen_size = ScreenSize{};
const WORLD_SPACE_SIZE = 20;

fn framebufferSizeCallback(window: *glfw.Window, width: i32, height: i32) callconv(.c) void {
    _ = window;
    screen_size.height = height;
    screen_size.width = width;
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
