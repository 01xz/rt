const std = @import("std");
const config = @import("config");
const rt = @import("rt.zig");
const hittable = @import("hittable.zig");
const material = @import("material.zig");
const vec = @import("vec.zig");
const utils = @import("utils.zig");

const Camera = @import("Camera.zig");
const HitRecord = hittable.HitRecord;
const Hittable = hittable.Hittable;
const HittableList = hittable.HittableList;
const Material = material.Material;
const RandomGen = rt.RandomGen;
const Vec3 = rt.Vec3;
const Color = rt.Color;
const Point = rt.Point;
const Float = rt.Float;

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

    var rng = RandomGen.init(@bitCast(std.time.timestamp()));

    // materials
    const mat_ground = Material.lambertian(Color{ 0.5, 0.5, 0.5 });
    const mat1 = Material.dielectric(1.5);
    const mat2 = Material.lambertian(Color{ 0.4, 0.2, 0.1 });
    const mat3 = Material.metal(Color{ 0.7, 0.6, 0.5 }, 0.0);

    // the world
    var world = HittableList.init(allocator);
    try world.add(Hittable.sphere(Point{ 0.0, -1000, 0.0 }, 1000.0, mat_ground));
    try world.add(Hittable.sphere(Point{ 0, 1, 0 }, 1.0, mat1));
    try world.add(Hittable.sphere(Point{ -4, 1, 0 }, 1.0, mat2));
    try world.add(Hittable.sphere(Point{ 4, 1, 0 }, 1.0, mat3));

    var a: i8 = -11;
    while (a < 11) {
        var b: i8 = -11;
        while (b < 11) {
            const choose_mat = utils.getRandom(&rng, Float);
            const centor = Point{
                @as(Float, @floatFromInt(a)) + 0.9 * utils.getRandom(&rng, Float),
                0.2,
                @as(Float, @floatFromInt(b)) + 0.9 * utils.getRandom(&rng, Float),
            };

            if (vec.vlen(centor - Point{ 4.0, 0.2, 0.0 }) > 0.9) {
                var mat: Material = undefined;
                if (choose_mat < 0.8) {
                    // diffuse
                    const albedo = utils.getRandomVec3InRange(&rng, 0.0, 1.0) * utils.getRandomVec3InRange(&rng, 0.0, 1.0);
                    mat = Material.lambertian(albedo);
                    try world.add(Hittable.sphere(centor, 0.2, mat));
                } else if (choose_mat < 0.95) {
                    // metal
                    const albedo = utils.getRandomVec3InRange(&rng, 0.5, 1.0);
                    const fuzz = utils.getRandom(&rng, Float);
                    mat = Material.metal(albedo, fuzz);
                    try world.add(Hittable.sphere(centor, 0.2, mat));
                } else {
                    // glass
                    mat = Material.dielectric(1.5);
                    try world.add(Hittable.sphere(centor, 0.2, mat));
                }
            }
            b += 1;
        }
        a += 1;
    }

    // the camera
    const camera = Camera.init(
        16.0 / 9.0,
        400,
        20,
        Point{ 13.0, 2.0, 3.0 },
        Point{ 0.0, 0.0, 0.0 },
        0.6,
        10.0,
        500,
        50,
    );

    // render the world
    const color_array = try camera.render(&world, allocator, &rng);

    var buffer_writer = std.io.bufferedWriter(std.io.getStdOut().writer());
    var writer = buffer_writer.writer();

    std.debug.print("start writing PPM ...\n", .{});

    try writePPM(&writer, color_array);

    try buffer_writer.flush();

    std.debug.print("writing PPM done\n", .{});
}
