const std = @import("std");
const config = @import("config");
const vec = @import("vec.zig");
const hittable = @import("hittable.zig");

const Camera = @import("Camera.zig");
const HitRecord = hittable.HitRecord;
const HittableList = hittable.HittableList;
const Sphere = hittable.Sphere;
const Vec3 = vec.Vec3;
const Point = Vec3(f64);

fn writePPM(writer: anytype, colored_pixels: [][]const i64) !void {
    const image_height = colored_pixels.len;
    const image_width = colored_pixels[0].len;

    try writer.print("P3\n{d} {d}\n255\n", .{ image_width, image_height });

    for (colored_pixels) |row| {
        for (row) |p| {
            const r = (p >> 16) & 0xff;
            const g = (p >> 8) & 0xff;
            const b = p & 0xff;
            try writer.print("{d} {d} {d}\n", .{ r, g, b });
        }
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();

    const allocator = arena.allocator();

    // the world
    var world = HittableList.init(allocator);
    try world.add(.{ .sphere = Sphere.init(Point{ 0.0, 0.0, -1.0 }, 0.5) });
    try world.add(.{ .sphere = Sphere.init(Point{ 0.0, -100.5, -1.0 }, 100.0) });

    // render the world
    const camera = Camera.init(
        16.0 / 9.0,
        400,
        100,
    );
    const color_array = try camera.render(&world, allocator);

    var buffer_writer = std.io.bufferedWriter(std.io.getStdOut().writer());
    var writer = buffer_writer.writer();

    try writePPM(&writer, color_array);

    try buffer_writer.flush();

    std.debug.print("writing PPM done\n", .{});
}
