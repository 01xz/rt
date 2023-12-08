const std = @import("std");
const config = @import("config");

pub fn writePPM(writer: anytype) !void {
    const image_width = 256;
    const image_height = 256;

    try writer.print("P3\n{d} {d}\n255\n", .{ image_width, image_height });

    for (0..image_width) |i| {
        for (0..image_height) |j| {
            const r: f64 = @as(f64, @floatFromInt(i)) / @as(f64, @floatFromInt(image_width - 1));
            const g: f64 = @as(f64, @floatFromInt(j)) / @as(f64, @floatFromInt(image_height - 1));
            const b: f64 = 0.25;
            const ir: u8 = @intFromFloat(255.999 * r);
            const ig: u8 = @intFromFloat(255.999 * g);
            const ib: u8 = @intFromFloat(255.999 * b);
            try writer.print("{d} {d} {d}\n", .{ ir, ig, ib });
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
