const std = @import("std");
const glfw = @import("libs/mach-glfw/build.zig");

fn addGLFW(b: *std.build.Builder, exe: *std.build.LibExeObjStep) !void {
    exe.addPackagePath("glfw", "libs/mach-glfw/src/main.zig");
    try glfw.link(b, exe, .{});
}

fn addGlad(_: *std.build.Builder, exe: *std.build.LibExeObjStep) !void {
    exe.addIncludePath("libs/glad/include");
    exe.addCSourceFile("libs/glad/src/gl.c", &[_][]const u8 { "-std=c99", "-Ofast" } );
    
    if (exe.target.isDarwin()) {
    } else {
    }
}

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("redesigned-enigma", "src/main.zig");
    // addGlad(b, exe) catch unreachable;
    addGLFW(b, exe) catch unreachable;
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_tests = b.addTest("src/main.zig");
    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}
