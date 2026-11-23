const std = @import("std");
const manifest = @import("build.zig.zon");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const wasm_target = b.resolveTargetQuery(.{
        .cpu_arch = .wasm32,
        .os_tag = .freestanding,
    });

    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .ReleaseSmall,
    });

    const options = b.addOptions();
    options.addOption([]const u8, "version", manifest.version);

    const known_folders = b.dependency("known_folders", .{
        .target = target,
        .optimize = optimize,
    });

    const imports = [_]std.Build.Module.Import{
        .{ .name = "known_folders", .module = known_folders.module("known-folders") },
    };

    const sable = build_exe(b, "sbl", "sable/main.zig", target, optimize, options, &imports);

    const sbl_wasm = b.createModule(.{
        .root_source_file = b.path("sable/main.zig"),
        .target = wasm_target,
        .optimize = .ReleaseSmall,
    });
    sbl_wasm.addImport("build_options", options.createModule());
    sbl_wasm.addImport("sbl", sbl_wasm);

    const wasm = b.addExecutable(.{
        .name = "sbl",
        .root_module = b.createModule(.{
            .root_source_file = b.path("sable/wasm.zig"),
            .target = wasm_target,
            .optimize = .ReleaseSmall,
            .imports = &.{.{ .name = "sbl", .module = sbl_wasm }},
        }),
    });
    wasm.entry = .disabled;
    wasm.rdynamic = true;

    const sable_mod_tests = b.addTest(.{ .root_module = sable });

    const run_sable_mod_tests = b.addRunArtifact(sable_mod_tests);

    const web_step = b.step("web", "Build wasm");
    const install_wasm = b.addInstallFileWithDir(wasm.getEmittedBin(), .prefix, "www/sbl.wasm");
    const install_web_files = b.addInstallDirectory(.{
        .source_dir = b.path("web"),
        .install_dir = .prefix,
        .install_subdir = "www",
    });
    web_step.dependOn(&install_wasm.step);
    web_step.dependOn(&install_web_files.step);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_sable_mod_tests.step);
}

fn build_exe(
    b: *std.Build,
    comptime name: []const u8,
    src: []const u8,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    options: *std.Build.Step.Options,
    imports: []const std.Build.Module.Import,
) *std.Build.Module {
    const module = b.addModule(name, .{
        .root_source_file = b.path(src),
        .target = target,
        .optimize = optimize,
        .imports = imports,
    });

    module.addImport(name, module);
    module.addOptions("build_options", options);

    const exe = b.addExecutable(.{
        .name = name,
        .root_module = module,
    });

    b.installArtifact(exe);

    const build_step = b.step(name, "Build the " ++ name ++ " executable");
    build_step.dependOn(&exe.step);

    const run_step = b.step("run-" ++ name, "Run the " ++ name ++ " executable");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());
    run_cmd.addPassthruArgs();

    return module;
}
