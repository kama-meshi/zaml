const std = @import("std");
const ChildProcess = std.ChildProcess;
const EmitOption = std.EmitOption;

pub fn build(b: *std.build.Builder) !void {
    // Find Python header file
    const result = try ChildProcess.exec(.{
        .allocator = std.heap.page_allocator,
        .argv = &[_][]const u8{
            "python",
            "-c",
            "import sysconfig; print(sysconfig.get_path(\"include\"), end=\"\")",
        },
    });
    const includeDir = result.stdout;

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const lib = b.addSharedLibrary("zaml", "zamlmodule.zig", .unversioned);
    lib.addIncludeDir(includeDir);
    lib.setBuildMode(mode);
    lib.linkage = .dynamic;
    lib.linker_allow_shlib_undefined = true;
    lib.linkSystemLibraryName("c");
    // FIXME: Match the out file of setup.py!!
    // const target = lib.target_info.target;
    // const arch = target.cpu.arch;
    // const os = target.os.tag;
    // const version = target.os.getVersionRange();
    // lib.emit_bin = .{ .emit_to = path };
    lib.install();

    const main_tests = b.addTest("zamlmodule.zig");
    main_tests.addIncludeDir(includeDir);
    main_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);
}
