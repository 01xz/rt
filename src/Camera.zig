const Camera = @This();

const std = @import("std");
const hittable = @import("hittable.zig");
const vec = @import("vec.zig");
const utils = @import("utils.zig");
const v3 = vec.vec3;

const Ray = @import("Ray.zig");
const Interval = @import("Interval.zig");
const Allocator = std.mem.Allocator;
const HitRecord = hittable.HitRecord;
const HittableList = hittable.HittableList;
const RandomGen = utils.RandomGen;
const Vec3 = vec.Vec3;
const Color = Vec3(f64);
const Point = Vec3(f64);

aspect_ratio: f64,

image_width: u32,
image_height: u32,

samples_per_pixel: u32,

centor: Point,

pixel00_loc: Point,

pixel_delta_u: Vec3(f64),
pixel_delta_v: Vec3(f64),

pub fn init(
    comptime aspect_ratio: f64,
    comptime image_width: u32,
    comptime samples_per_pixel: u32,
) Camera {
    const image_height: u32 = blk: {
        const height: u32 = @intFromFloat(@as(f64, @floatFromInt(image_width)) / aspect_ratio);
        break :blk if (height < 1) 1 else height;
    };

    const focal_length: f64 = 1.0;

    const viewport_height: f64 = 2.0;
    const viewport_width: f64 = viewport_height *
        (@as(f64, @floatFromInt(image_width)) / @as(f64, @floatFromInt(image_height)));

    const centor = Point{ 0, 0, 0 };

    // viewport edges
    const viewport_u = Point{ viewport_width, 0.0, 0.0 };
    const viewport_v = Point{ 0.0, -viewport_height, 0.0 };

    // pixel delta
    const pixel_delta_u = viewport_u / v3(@floatFromInt(image_width));
    const pixel_delta_v = viewport_v / v3(@floatFromInt(image_height));

    const viewport_upper_left = centor - Point{ 0, 0, focal_length } - (viewport_u * v3(0.5)) - (viewport_v * v3(0.5));

    const pixel00_loc = viewport_upper_left + (pixel_delta_u + pixel_delta_v) * v3(0.5);

    return .{
        .aspect_ratio = aspect_ratio,
        .image_width = image_width,
        .image_height = image_height,
        .samples_per_pixel = samples_per_pixel,
        .centor = centor,
        .pixel00_loc = pixel00_loc,
        .pixel_delta_u = pixel_delta_u,
        .pixel_delta_v = pixel_delta_v,
    };
}

pub fn render(self: *const Camera, world: *const HittableList, allocator: Allocator) ![][]i64 {
    var colored_pixels = try allocator.alloc([]i64, self.image_height);
    for (colored_pixels) |*item| {
        item.* = try allocator.alloc(i64, self.image_width);
    }

    var rng = RandomGen.init(@bitCast(std.time.timestamp()));

    for (0..self.image_height) |j| {
        for (0..self.image_width) |i| {
            var pixel_color = Color{ 0.0, 0.0, 0.0 };
            for (0..self.samples_per_pixel) |_| {
                const ray = self.getRay(i, j, &rng);
                const ray_color = rayColor(&ray, world, &rng);
                pixel_color += ray_color;
            }
            colored_pixels[j][i] = writeColor(&pixel_color, self.samples_per_pixel);
        }
    }

    return colored_pixels;
}

fn getRay(self: *const Camera, i: usize, j: usize, rng: *RandomGen) Ray {
    const pixel_centor = self.pixel00_loc + self.pixel_delta_u * v3(@floatFromInt(i)) + self.pixel_delta_v * v3(@floatFromInt(j));

    const pixel_sample_square = blk: {
        const px = -0.5 + utils.getRandom(rng, f64);
        const py = -0.5 + utils.getRandom(rng, f64);
        break :blk (self.pixel_delta_u * v3(px)) + (self.pixel_delta_v * v3(py));
    };

    const pixel_sample = pixel_centor + pixel_sample_square;

    const ray_origin = self.centor;
    const ray_direction = pixel_sample - ray_origin;

    return Ray.init(ray_origin, ray_direction);
}

fn rayColor(ray: *const Ray, world: *const HittableList, rng: *RandomGen) Color {
    const inf = std.math.inf(f64);

    var rec: HitRecord = undefined;

    // normals-colored world
    if (world.hit(ray, Interval.init(0.0, inf), &rec)) {
        const direction = utils.getRandomOnHemiSphere(rng, rec.normal);
        const reflected_ray = Ray.init(rec.point, direction);
        return rayColor(&reflected_ray, world, rng) * v3(0.5);
    }

    const color_start = Color{ 1.0, 1.0, 1.0 };
    const color_end = Color{ 0.5, 0.7, 1.0 };

    const ray_unit_vec = vec.unit(ray.direction);

    // scale `y()` to [0.0, 1.0]
    const a = 0.5 * (ray_unit_vec[1] + 1.0);

    // (1 - a) * start + a * end
    return color_start * v3(1.0 - a) + color_end * v3(a);
}

inline fn writeColor(color: *const Color, samples_per_pixel: u32) i64 {
    const scale = 1.0 / @as(f64, @floatFromInt(samples_per_pixel));
    const intensity = Interval.init(0.000, 0.999);
    const r: i64 = @intFromFloat(256.0 * intensity.clamp(color[0] * scale));
    const g: i64 = @intFromFloat(256.0 * intensity.clamp(color[1] * scale));
    const b: i64 = @intFromFloat(256.0 * intensity.clamp(color[2] * scale));
    return r << 16 | g << 8 | b;
}
