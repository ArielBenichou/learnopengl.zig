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
    // glfw: init & config
    glfw.init() catch {
        std.log.err("GLFW Initilization failed", .{});
        std.process.exit(1);
    };
    defer glfw.terminate();

    // glfw: window creation
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
        WindowSize.width,
        WindowSize.height,
        "LearnOpenGL: ZIG Edition",
        null,
    ) catch {
        std.log.err("GLFW Window creation failed", .{});
        glfw.terminate();
        std.process.exit(1);
    };
    defer window.destroy();

    glfw.makeContextCurrent(window);
    _ = window.setFramebufferSizeCallback(framebufferSizeCallback);

    // OpenGL: load profile
    try zopengl.loadCoreProfile(
        glfw.getProcAddress,
        gl_major,
        gl_minor,
    );

    // Allocators
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();
    var arena_allocator_state = std.heap.ArenaAllocator.init(allocator);
    defer arena_allocator_state.deinit();
    const arena = arena_allocator_state.allocator();

    // zstbi: init
    zstbi.init(allocator);
    zstbi.setFlipVerticallyOnLoad(true);
    defer zstbi.deinit();

    // shader: create
    const shader = try Shader.init(
        arena,
        "./src/shaders/default.vert.glsl",
        "./src/shaders/default.frag.glsl",
    );
    defer shader.deinit();

    // zig fmt: off
    const vertices = [_]gl.Float {
        // positions       // tex coords
        -0.5, -0.5, -0.5,  0.0, 0.0,
         0.5, -0.5, -0.5,  1.0, 0.0,
         0.5,  0.5, -0.5,  1.0, 1.0,
         0.5,  0.5, -0.5,  1.0, 1.0,
        -0.5,  0.5, -0.5,  0.0, 1.0,
        -0.5, -0.5, -0.5,  0.0, 0.0,

        -0.5, -0.5,  0.5,  0.0, 0.0,
         0.5, -0.5,  0.5,  1.0, 0.0,
         0.5,  0.5,  0.5,  1.0, 1.0,
         0.5,  0.5,  0.5,  1.0, 1.0,
        -0.5,  0.5,  0.5,  0.0, 1.0,
        -0.5, -0.5,  0.5,  0.0, 0.0,

        -0.5,  0.5,  0.5,  1.0, 0.0,
        -0.5,  0.5, -0.5,  1.0, 1.0,
        -0.5, -0.5, -0.5,  0.0, 1.0,
        -0.5, -0.5, -0.5,  0.0, 1.0,
        -0.5, -0.5,  0.5,  0.0, 0.0,
        -0.5,  0.5,  0.5,  1.0, 0.0,

         0.5,  0.5,  0.5,  1.0, 0.0,
         0.5,  0.5, -0.5,  1.0, 1.0,
         0.5, -0.5, -0.5,  0.0, 1.0,
         0.5, -0.5, -0.5,  0.0, 1.0,
         0.5, -0.5,  0.5,  0.0, 0.0,
         0.5,  0.5,  0.5,  1.0, 0.0,

        -0.5, -0.5, -0.5,  0.0, 1.0,
         0.5, -0.5, -0.5,  1.0, 1.0,
         0.5, -0.5,  0.5,  1.0, 0.0,
         0.5, -0.5,  0.5,  1.0, 0.0,
        -0.5, -0.5,  0.5,  0.0, 0.0,
        -0.5, -0.5, -0.5,  0.0, 1.0,

        -0.5,  0.5, -0.5,  0.0, 1.0,
         0.5,  0.5, -0.5,  1.0, 1.0,
         0.5,  0.5,  0.5,  1.0, 0.0,
         0.5,  0.5,  0.5,  1.0, 0.0,
        -0.5,  0.5,  0.5,  0.0, 0.0,
        -0.5,  0.5, -0.5,  0.0, 1.0
    };

    const cube_positions = [_][3]f32{
        .{  0.0,  0.0,  0.0  },
        .{  2.0,  5.0, -15.0 },
        .{ -1.5, -2.2, -2.5  },
        .{ -3.8, -2.0, -12.3 },
        .{  2.4, -0.4, -3.5  },
        .{ -1.7,  3.0, -7.5  },
        .{  1.3, -2.0, -2.5  },
        .{  1.5,  2.0, -2.5  },
        .{  1.5,  0.2, -1.5  },
        .{ -1.3,  1.0, -1.5  },
    };
    // zig fmt: on

    const rect_vao = VertexArray.init();
    defer rect_vao.deinit();
    rect_vao.bind();

    var rect_vbo = VertexBuffer.init(&vertices, 5, .StaticDraw);
    defer rect_vbo.deinit();
    rect_vbo.bind();

    // pos attrib
    rect_vbo.addAttribute(3, gl.FLOAT, gl.FALSE);
    // texcoord attrib
    rect_vbo.addAttribute(2, gl.FLOAT, gl.FALSE);

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

    gl.enable(gl.DEPTH_TEST);

    shader.use();
    shader.setInt("base_tex", 0);
    shader.setInt("overlay_tex", 1);

    var model: [16]f32 = undefined;

    var view: [16]f32 = undefined;

    var projection: [16]f32 = undefined;

    glfw.swapInterval(1);

    while (!window.shouldClose()) {
        // UPDATE
        const current_frame = @as(f32, @floatCast(glfw.getTime()));
        state.delta_time = current_frame - state.last_frame;
        state.last_frame = current_frame;
        processInput(window);

        // DRAW
        gl.clearColor(0.2, 0.3, 0.3, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

        gl.activeTexture(gl.TEXTURE0);
        crate_tex.bind();
        gl.activeTexture(gl.TEXTURE1);
        face_tex.bind();
        rect_vao.bind();

        const viewM = zm.lookAtRh(
            camera.pos,
            camera.pos + camera.front,
            camera.up,
        );
        zm.storeMat(&view, viewM);
        shader.setMat("view", view);

        const projM = x: {
            const window_size = window.getSize();
            const fov = @as(f32, @floatFromInt(window_size[0])) / @as(f32, @floatFromInt(window_size[1]));
            const projM = zm.perspectiveFovRhGl(std.math.degreesToRadians(45), fov, 0.1, 100.0);
            break :x projM;
        };
        zm.storeMat(&projection, projM);
        shader.setMat("projection", projection);

        for (cube_positions, 0..) |cube_position, i| {
            const cube_trans = zm.translation(cube_position[0], cube_position[1], cube_position[2]);
            // alternate -1 / 1
            const rotation_direction = ((@mod(@as(f32, @floatFromInt(i + 1)), 2.0)) * 2.0) - 1.0;
            const cube_rot = zm.matFromAxisAngle(
                zm.f32x4(1, 0.3, 0.5, 1.0),
                std.math.degreesToRadians(55) * rotation_direction * @as(f32, @floatCast(glfw.getTime() * 0.5)),
            );

            const modelM = zm.mul(
                cube_rot,
                cube_trans,
            );
            zm.storeMat(&model, modelM);
            shader.setMat("model", model);

            gl.drawArrays(gl.TRIANGLES, 0, 36);
        }

        window.swapBuffers();
        glfw.pollEvents();
    }
}

const WindowSize = struct {
    pub const width: u32 = 800;
    pub const height: u32 = 600;
};

const Camera = struct {
    pos: zm.Vec,
    front: zm.Vec,
    up: zm.Vec,
    speed: f32,
};
var camera = Camera{
    .pos = zm.loadArr3(.{ 0, 0, 3 }),
    .front = zm.loadArr3(.{ 0, 0, -1 }),
    .up = zm.loadArr3(.{ 0, 1, 0 }),
    .speed = 2.5,
};

const State = struct {
    delta_time: f32 = 0,
    last_frame: f32 = 0,
};

var state = State{};

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
    const camera_speed = camera.speed * state.delta_time;
    if (window.getKey(.w) == .press) {
        camera.pos += zm.splat(zm.Vec, camera_speed) * camera.front;
    }
    if (window.getKey(.s) == .press) {
        camera.pos -= zm.splat(zm.Vec, camera_speed) * camera.front;
    }
    if (window.getKey(.a) == .press) {
        camera.pos -= zm.normalize3(zm.cross3(camera.front, camera.up)) * zm.splat(zm.Vec, camera_speed);
    }
    if (window.getKey(.d) == .press) {
        camera.pos += zm.normalize3(zm.cross3(camera.front, camera.up)) * zm.splat(zm.Vec, camera_speed);
    }
}
