const std = @import("std");
const config = @import("config");

const Vec3 = @import("vec3.zig").Vec3;
const Color = Vec3(f64);

pub fn writeColor(writer: anytype, color: *const Color) !void {
    const icolor = Vec3(u8).init([_]u8{
        @intFromFloat(255.999 * color.x()),
        @intFromFloat(255.999 * color.y()),
        @intFromFloat(255.999 * color.z()),
    });
    try writer.print("{d} {d} {d}\n", .{ icolor.x(), icolor.y(), icolor.z() });
}

pub fn writePPM(writer: anytype) !void {
    const image_width = 256;
    const image_height = 256;

    try writer.print("P3\n{d} {d}\n255\n", .{ image_width, image_height });

    for (0..image_height) |j| {
        for (0..image_width) |i| {
            const r: f64 = @as(f64, @floatFromInt(i)) / @as(f64, @floatFromInt(image_width - 1));
            const g: f64 = @as(f64, @floatFromInt(j)) / @as(f64, @floatFromInt(image_height - 1));
            const b: f64 = 0.25;
            const color = Color.init([_]f64{ r, g, b });
            try writeColor(writer, &color);
        }
    }
}

pub fn main() !void {
    var buffer_writer = std.io.bufferedWriter(std.io.getStdOut().writer());
    var writer = buffer_writer.writer();

    try writePPM(&writer);

    try buffer_writer.flush();

    std.debug.print("writing PPM done\n", .{});
}
