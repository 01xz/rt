const std = @import("std");

pub fn build(b: *std.Build) void {
    const version = b.option([]const u8, "version", "rt version string") orelse "0.0.0";

    const options = b.addOptions();

    options.addOption([]const u8, "version", version);

    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "rt",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    exe.addOptions("config", options);

    b.installArtifact(exe);
}
