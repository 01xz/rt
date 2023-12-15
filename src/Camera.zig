const Camera = @This();

const std = @import("std");
const rt = @import("rt.zig");
const hittable = @import("hittable.zig");
const utils = @import("utils.zig");
const material = @import("material.zig");
const vec = @import("vec.zig");

const Ray = @import("Ray.zig");
const Interval = @import("Interval.zig");
const Allocator = std.mem.Allocator;
const HitRecord = hittable.HitRecord;
const HittableList = hittable.HittableList;
const Scatter = material.Scatter;
const Material = material.Material;
const RandomGen = rt.RandomGen;
const Vec3 = rt.Vec3;
const Color = rt.Color;
const Point = rt.Point;
const Float = rt.Float;

const inf = rt.inf;

const v3 = rt.v3;

aspect_ratio: Float,

image_width: u32,
image_height: u32,

vertical_fov: Float,

samples_per_pixel: u32,

max_depth: u32,

centor: Point,

pixel00_loc: Point,

pixel_delta_u: Vec3,
pixel_delta_v: Vec3,

pub fn init(
    comptime aspect_ratio: Float,
    comptime image_width: u32,
    comptime vertical_fov: Float,
    comptime samples_per_pixel: u32,
    comptime max_depth: u32,
) Camera {
    const image_height: u32 = blk: {
        const height: u32 = @intFromFloat(@as(Float, @floatFromInt(image_width)) / aspect_ratio);
        break :blk if (height < 1) 1 else height;
    };

    const focal_length: Float = 1.0;

    const theta = utils.radiansFromDegrees(vertical_fov);
    const h = @tan(theta / 2.0);

    const viewport_height: Float = 2.0 * h * focal_length;
    const viewport_width: Float = viewport_height *
        (@as(Float, @floatFromInt(image_width)) / @as(Float, @floatFromInt(image_height)));

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
        .vertical_fov = vertical_fov,
        .samples_per_pixel = samples_per_pixel,
        .max_depth = max_depth,
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
                const ray_color = rayColor(&ray, world, &rng, self.max_depth);
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
        const px = -0.5 + utils.getRandom(rng, Float);
        const py = -0.5 + utils.getRandom(rng, Float);
        break :blk (self.pixel_delta_u * v3(px)) + (self.pixel_delta_v * v3(py));
    };

    const pixel_sample = pixel_centor + pixel_sample_square;

    const ray_origin = self.centor;
    const ray_direction = pixel_sample - ray_origin;

    return Ray.init(ray_origin, ray_direction);
}

// TODO: use loop rather than recursion
fn rayColor(ray: *const Ray, world: *const HittableList, rng: *RandomGen, depth: u32) Color {
    // reach the ray bounce limit
    if (depth <= 0) {
        return Color{ 0.0, 0.0, 0.0 };
    }

    if (world.hit(ray, Interval.init(0.001, inf))) |rec| {
        if (rec.mat.scatter(ray, &rec, rng)) |s| {
            return s.attenuation * rayColor(&s.scattered, world, rng, depth - 1);
        }
        return Color{ 0.0, 0.0, 0.0 };
    }

    const color_start = Color{ 1.0, 1.0, 1.0 };
    const color_end = Color{ 0.5, 0.7, 1.0 };

    const ray_unit_vec = vec.unit(ray.direction);

    // scale `y()` to [0.0, 1.0]
    const a = 0.5 * (ray_unit_vec[1] + 1.0);

    // (1 - a) * start + a * end
    return color_start * v3(1.0 - a) + color_end * v3(a);
}

inline fn gammaCorrection(color: *const Color) Color {
    // gamma 2
    return Color{
        @sqrt(color[0]),
        @sqrt(color[1]),
        @sqrt(color[2]),
    };
}

inline fn writeColor(color: *const Color, samples_per_pixel: u32) i64 {
    const scale = 1.0 / @as(Float, @floatFromInt(samples_per_pixel));
    const scaled_color = color.* * v3(scale);
    const corrected_color = gammaCorrection(&scaled_color);
    const intensity = Interval.init(0.000, 0.999);
    const r: i64 = @intFromFloat(256.0 * intensity.clamp(corrected_color[0]));
    const g: i64 = @intFromFloat(256.0 * intensity.clamp(corrected_color[1]));
    const b: i64 = @intFromFloat(256.0 * intensity.clamp(corrected_color[2]));
    return r << 16 | g << 8 | b;
}
