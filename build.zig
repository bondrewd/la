const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const lib = b.addStaticLibrary("la", "src/la.zig");
    lib.setBuildMode(mode);
    lib.setOutputDir("./lib");
    lib.install();

    var la_tests = b.addTest("src/test.zig");
    la_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&la_tests.step);
}
