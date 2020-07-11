const std = @import("std");
const Builder = std.build.Builder;
const Version = std.build.Version;
const LibExeObjStep = std.build.LibExeObjStep;

pub fn build(b: *Builder) void {
    const mode = std.builtin.Mode.Debug;
    const lib = b.addSharedLibrary("zigproc", "src/msgpack.zig", b.version(0, 0, 1));

    set_build_options(lib);
    lib.setBuildMode(mode);
    // lib.setOutputDir("./");
    lib.install();

    const test_step = b.addTest("src/msgpack.zig");
    const test_cmd = b.step("test", "Run the tests");
    test_cmd.dependOn(&test_step.step);

    set_build_options(test_step);
    test_step.setBuildMode(mode);

    b.default_step.dependOn(test_cmd);
}

fn set_build_options(step: *LibExeObjStep) void {
    step.single_threaded = true;
    step.force_pic = true;
}