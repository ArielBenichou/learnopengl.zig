const std = @import("std");
const builtin = @import("builtin");
const glfw = @import("zglfw");
const zopengl = @import("zopengl");
const gl = zopengl.bindings;

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
    // glfw.windowHintTyped(.client_api, .opengl_api);
    glfw.windowHintTyped(.doublebuffer, true);

    const initial_screen_size = .{
        .width = 800,
        .height = 600,
    };
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

    // glfw.swapInterval(1);

    while (!window.shouldClose()) {
        processInput(window);

        gl.clearColor(0.2, 0.3, 0.3, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT);

        window.swapBuffers();
        glfw.pollEvents();
    }
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
