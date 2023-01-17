const std = @import("std");
const glfw = @import("glfw");
const gl = @import("gl");

// https://github.com/hexops/mach-glfw-opengl-example/blob/main/src/main.zig
fn glGetProcAddress(_: glfw.GLProc, proc: [:0]const u8) ?gl.FunctionPointer {
    return glfw.getProcAddress(proc);
}

pub fn main() !void {
    _ = glfw.init(.{});
    defer glfw.terminate();

    const window = glfw.Window.create(600, 600, "snake", null, null, .{
        .opengl_profile = .opengl_core_profile,
        .context_version_major = 3,
        .context_version_minor = 3,
        .opengl_forward_compat = true
    }).?;
    defer window.destroy();

    glfw.makeContextCurrent(window);

    const proc: glfw.GLProc = undefined;
    try gl.load(proc, glGetProcAddress);

    while (!window.shouldClose()) {
        glfw.pollEvents();

        gl.clearColor(1, 0, 1, 1);
        gl.clear(gl.COLOR_BUFFER_BIT);

        window.swapBuffers();
    }
}

test "test1" {}
