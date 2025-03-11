const std = @import("std");
const builtin = @import("builtin");

const glfw = @import("zglfw");
const zgui = @import("zgui");
const zm = @import("zmath");
const zopengl = @import("zopengl");
const gl = zopengl.bindings;
const zstbi = @import("zstbi");

const Camera = @import("Camera.zig").Camera;
const IndexBuffer = @import("IndexBuffer.zig").IndexBuffer;
const Shader = @import("Shader.zig").Shader;
const Texture2D = @import("Texture2D.zig").Texture2D;
const VertexArray = @import("VertexArray.zig").VertexArray;
const VertexBuffer = @import("VertexBuffer.zig").VertexBuffer;

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
    _ = window.setCursorPosCallback(mouseCallback);
    _ = window.setScrollCallback(scrollCallback);

    window.setSizeLimits(400, 400, -1, -1);
    try window.setInputMode(.cursor, .normal);

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

    // zgui: init
    zgui.init(allocator);
    defer zgui.deinit();

    // TODO: wait for zgui to resolve error
    // Configure ImGui with multi-viewport support before backend initialization
    // zgui.io.setConfigFlags(.{
    //     .viewport_enable = true,
    //     .dock_enable = true,
    // });
    // io.config_view_ports_no_decoration = false; // Enable window decorations
    // io.config_view_ports_no_task_bar_icon = true; // Don't show separate taskbar icons
    // io.config_view_ports_no_auto_merge = true; // Don't auto-merge windows back

    zgui.backend.init(window);
    defer zgui.backend.deinit();

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
        //---UPDATE
        { // Update Time State
            const current_frame = @as(f32, @floatCast(glfw.getTime()));
            state.delta_time = current_frame - state.last_frame;
            state.last_frame = current_frame;
        }
        processInput(window);

        //---DRAW
        glfw.pollEvents();

        { // Clear
            gl.clearColor(0.2, 0.3, 0.3, 1.0);
            gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
        }

        { // Draw Cubes
            gl.activeTexture(gl.TEXTURE0);
            crate_tex.bind();
            gl.activeTexture(gl.TEXTURE1);
            face_tex.bind();
            rect_vao.bind();

            const viewM = state.camera.getViewMatrix();
            zm.storeMat(&view, viewM);
            shader.setMat("view", view);

            const projM = x: {
                const window_size = window.getSize();
                const fov = @as(f32, @floatFromInt(window_size[0])) / @as(f32, @floatFromInt(window_size[1]));
                const projM = zm.perspectiveFovRhGl(std.math.degreesToRadians(state.camera.zoom), fov, 0.1, 100.0);
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
        }

        { // zgui
            const framebuffer_size = window.getFramebufferSize();

            zgui.backend.newFrame(@intCast(framebuffer_size[0]), @intCast(framebuffer_size[1]));

            // Set the starting window position and size to custom values
            zgui.setNextWindowPos(.{ .x = 20.0, .y = 20.0, .cond = .first_use_ever });
            zgui.setNextWindowSize(.{ .w = -1.0, .h = -1.0, .cond = .first_use_ever });

            if (zgui.begin("My window", .{})) {
                if (zgui.button("Press me!", .{ .w = 200.0 })) {
                    std.debug.print("Button pressed\n", .{});
                }
            }
            zgui.end();

            renderCameraControlWindow();

            zgui.backend.draw();
        }

        window.swapBuffers();
    }
}

const WindowSize = struct {
    pub const width: u32 = 800;
    pub const height: u32 = 600;
};

const State = struct {
    delta_time: f32 = 0,
    last_frame: f32 = 0,
    mouse: struct {
        did_init: bool = false,
        last_x: f32 = 400,
        last_y: f32 = 400,
    },
    camera: Camera = Camera.initDefault(),
};

var state = State{
    .mouse = .{},
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

fn mouseCallback(window: *glfw.Window, xpos: f64, ypos: f64) callconv(.c) void {
    _ = window;
    const pos_x: f32 = @floatCast(xpos);
    const pos_y: f32 = @floatCast(ypos);

    if (state.mouse.did_init == false) {
        state.mouse.last_x = pos_x;
        state.mouse.last_y = pos_y;
        state.mouse.did_init = true;
    }

    const offset_x = pos_x - state.mouse.last_x;
    const offset_y = state.mouse.last_y - pos_y;
    state.mouse.last_x = pos_x;
    state.mouse.last_y = pos_y;

    state.camera.processMouseMovement(offset_x, offset_y, true);
}

fn scrollCallback(window: *glfw.Window, xoffset: f64, yoffset: f64) callconv(.c) void {
    _ = xoffset;
    _ = window;

    state.camera.processMouseScroll(@floatCast(yoffset));
}

fn processInput(window: *glfw.Window) callconv(.c) void {
    if (window.getKey(.escape) == .press) {
        window.setShouldClose(true);
    }
    if (window.getKey(.w) == .press) {
        state.camera.processKeyboard(.Forward, state.delta_time);
    }
    if (window.getKey(.s) == .press) {
        state.camera.processKeyboard(.Backward, state.delta_time);
    }
    if (window.getKey(.a) == .press) {
        state.camera.processKeyboard(.Left, state.delta_time);
    }
    if (window.getKey(.d) == .press) {
        state.camera.processKeyboard(.Right, state.delta_time);
    }
}

// UI Components
fn renderCameraControlWindow() void {
    // Set the starting window position and size
    zgui.setNextWindowPos(.{
        .x = 20.0,
        .y = 200.0,
        .cond = .first_use_ever,
    });
    zgui.setNextWindowSize(.{
        .w = 350.0,
        .h = 400.0,
        .cond = .first_use_ever,
    });

    if (zgui.begin("Camera Controls", .{})) {
        zgui.spacing();

        // Camera Position
        zgui.separatorText("Position");

        var position = zm.vecToArr3(state.camera.position);

        if (zgui.dragFloat3("Position", .{
            .v = &position,
            .speed = 0.1,
        })) {
            state.camera.position = zm.f32x4(
                position[0],
                position[1],
                position[2],
                0,
            );
            state.camera.updateCameraVectors();
        }

        if (zgui.button("Reset Position", .{})) {
            state.camera.position = zm.loadArr3(.{ 0, 0, 3 });
            state.camera.updateCameraVectors();
        }

        zgui.spacing();
        zgui.separatorText("Orientation");

        // Yaw and Pitch
        var yaw = state.camera.yaw;
        if (zgui.sliderFloat("Yaw", .{
            .v = &yaw,
            .min = -180,
            .max = 180,
        })) {
            state.camera.yaw = yaw;
            state.camera.updateCameraVectors();
        }

        var pitch = state.camera.pitch;
        if (zgui.sliderFloat("Pitch", .{
            .v = &pitch,
            .min = -89,
            .max = 89,
        })) {
            state.camera.pitch = pitch;
            state.camera.updateCameraVectors();
        }

        if (zgui.button("Reset Orientation", .{})) {
            state.camera.yaw = -90;
            state.camera.pitch = 0;
            state.camera.updateCameraVectors();
        }

        zgui.spacing();
        zgui.separatorText("Camera Settings");

        // Movement Speed
        var movement_speed = state.camera.movement_speed;
        if (zgui.sliderFloat("Movement Speed", .{
            .v = &movement_speed,
            .min = 0.1,
            .max = 10.0,
        })) {
            state.camera.movement_speed = movement_speed;
        }

        // Mouse Sensitivity
        var mouse_sensitivity = state.camera.mouse_sensitivity;
        if (zgui.sliderFloat("Mouse Sensitivity", .{
            .v = &mouse_sensitivity,
            .min = 0.01,
            .max = 1.0,
        })) {
            state.camera.mouse_sensitivity = mouse_sensitivity;
        }

        // Zoom/FOV
        var zoom = state.camera.zoom;
        if (zgui.sliderFloat("FOV (Zoom)", .{
            .v = &zoom,
            .min = 1,
            .max = 45,
        })) {
            state.camera.zoom = zoom;
        }

        if (zgui.button("Reset Camera Settings", .{})) {
            state.camera.movement_speed = 2.5;
            state.camera.mouse_sensitivity = 0.1;
            state.camera.zoom = 45;
        }

        zgui.spacing();
        zgui.separatorText("Camera Info");

        // Camera vectors display
        const front = zm.vecToArr3(state.camera.front);
        zgui.labelText(
            "Front",
            "({d:.2},{d:.2},{d:.2})",
            .{ front[0], front[1], front[2] },
        );

        const up = zm.vecToArr3(state.camera.up);
        zgui.labelText(
            "Up",
            "({d:.2},{d:.2},{d:.2})",
            .{ up[0], up[1], up[2] },
        );

        const right = zm.vecToArr3(state.camera.right);
        zgui.labelText(
            "Right",
            "({d:.2},{d:.2},{d:.2})",
            .{ right[0], right[1], right[2] },
        );
    }
    zgui.end();
}
