const std = @import("std");
const glfw = @import("glfw");

pub fn main() !void {
    _ = glfw.init(.{});
    defer glfw.terminate();

    const window = glfw.Window.create(600, 600, "redisigned-enigma", null, null, .{
        .client_api = .no_api,
    }).?;
    defer window.destroy();

    while (!window.shouldClose()) {
        glfw.pollEvents();
    }
}

test "test1" {
}
