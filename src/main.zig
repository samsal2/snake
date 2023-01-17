const std = @import("std");
const glfw = @import("glfw");
const gl = @import("gl");

pub const Shader = struct {
    id: u32 = 0,

    fn compile(source: [*]const u8, shaderType: c_uint, alloc: *const std.mem.Allocator) !u32 {
        var result = gl.createShader(shaderType);
        gl.shaderSource(result, 1, &source, null);
        gl.compileShader(result);

        var whu: i32 = undefined;
        gl.getShaderiv(result, gl.COMPILE_STATUS, &whu);
        if (whu == gl.FALSE) {
            defer gl.deleteShader(result);

            var length: i32 = undefined;
            gl.getShaderiv(result, gl.INFO_LOG_LENGTH, &length);

            var message = try alloc.alloc(u8, @intCast(usize, length));
            defer alloc.free(message);

            gl.getShaderInfoLog(result, length, &length, @ptrCast([*c]u8, message));

            const mtype: *const [4:0]u8 = if (shaderType == gl.VERTEX_SHADER) "VERT" else "FRAG";

            std.debug.print("Failed to compile shader(Type: {s})!\nError: {s}\n", .{
                mtype,
                message,
            });
        }

        return result;
    }

    pub fn create(vertexShader: [*]const u8, fragShader: [*]const u8, alloc: *const std.mem.Allocator) !Shader {
        const vx = try Shader.compile(vertexShader, gl.VERTEX_SHADER, alloc);
        const fg = try Shader.compile(fragShader, gl.FRAGMENT_SHADER, alloc);
        defer gl.deleteShader(vx);
        defer gl.deleteShader(fg);

        var result = Shader{};
        result.id = gl.createProgram();
        gl.attachShader(result.id, vx);
        gl.attachShader(result.id, fg);
        gl.linkProgram(result.id);

        var ok: i32 = 0;
        gl.getProgramiv(result.id, gl.LINK_STATUS, &ok);
        if (ok == gl.FALSE) {
            defer gl.deleteProgram(result.id);

            var error_size: i32 = undefined;
            gl.getProgramiv(result.id, gl.INFO_LOG_LENGTH, &error_size);

            var message = try alloc.alloc(u8, @intCast(usize, error_size));
            defer alloc.free(message);

            gl.getProgramInfoLog(result.id, error_size, &error_size, @ptrCast([*c]u8, message));
            std.debug.print("Error occured while linking shader program:\n\t{s}\n", .{message});
        }
        gl.validateProgram(result.id);

        return result;
    }

    pub fn destroy(self: Shader) Shader {
        gl.deleteProgram(self.id);
        return Shader{};
    }

    pub fn attach(self: Shader) void {
        gl.useProgram(self.id);
    }
};

const vertex = struct {
    x: f32,
    y: f32,
    r: f32,
    g: f32,
    b: f32,
};

const vertices = [3]vertex{
    vertex{ .x = -0.6, .y = -0.4, .r = 1.0, .g = 0.0, .b = 0.0 },
    vertex{ .x = 0.6, .y = -0.4, .r = 0.0, .g = 1.0, .b = 0.0 },
    vertex{ .x = 0.0, .y = 0.6, .r = 0.0, .g = 0.0, .b = 1.0 },
};


const vertex_shader_t =
    \\#version 330 core
    \\layout(location = 0) in vec2 vPos;
    \\layout(location = 1) in vec3 vCol;
    \\out vec4 outCol;
    \\void main() {
    \\  gl_Position = vec4(vPos, 0.0, 1.0);
    \\  outCol = vec4(vCol, 1.0);
    \\}
;
const fragment_shader_t =
    \\#version 330 core
    \\in vec4 outCol;
    \\out vec4 fragColor;
    \\void main() {
    \\ fragColor = outCol; 
    \\}
;

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

    var program = try Shader.create(vertex_shader_t, fragment_shader_t, &std.heap.page_allocator);
    defer program = program.destroy();

    var vbo: u32 = undefined;
    var vao: u32 = undefined;

    gl.genVertexArrays(1, &vao);    
    defer gl.deleteVertexArrays(1, &vao);

    gl.genBuffers(1, &vbo);    
    defer gl.deleteBuffers(1, &vbo);

    gl.bindVertexArray(vao);    
    gl.bindBuffer(gl.ARRAY_BUFFER, vbo);
    gl.bufferData(gl.ARRAY_BUFFER, @sizeOf(vertex) * 3, @ptrCast(*const void, &vertices), gl.STATIC_DRAW);

    const offset: usize = @sizeOf(f32) * 2;
    const stride: i32 = @sizeOf(vertex);

    gl.enableVertexAttribArray(0);
    gl.vertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, stride, null);
    gl.enableVertexAttribArray(1);
    gl.vertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, stride, @intToPtr(*i32, offset));

    gl.bindVertexArray(0);
    gl.bindBuffer(gl.ARRAY_BUFFER, 0);


    while (!window.shouldClose()) {

        // var w: c_int = 0;
        // var h: c_int = 0;
        // const size = window.getFramebufferSize();
        // w = @as(c_int, size.width);
        // h = @as(c_int, size.height);
        // gl.viewport(0, 0, @as(gl.GLsizei, @as(c_int, size.width)), @as(gl.GLsizei, @as(c_int, size.height)));

        gl.clearColor(0, 0, 0, 1);
        gl.clear(gl.COLOR_BUFFER_BIT);

        program.attach();
        gl.bindVertexArray(vao);
        gl.drawArrays(gl.TRIANGLES, 0, 3);    

        glfw.pollEvents();
        window.swapBuffers();

    }
}

test "test1" {}
