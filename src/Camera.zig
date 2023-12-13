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
const Vec3 = vec.Vec3;
const Color = Vec3(f64);
const Point = Vec3(f64);

aspect_ratio: f64,

image_width: u32,
image_height: u32,

centor: Point,

pixel00_loc: Point,

pixel_delta_u: Vec3(f64),
pixel_delta_v: Vec3(f64),

pub fn init(
    comptime aspect_ratio: f64,
    comptime image_width: u32,
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

    for (0..self.image_height) |j| {
        for (0..self.image_width) |i| {
            const ray = self.getRay(i, j);
            const pixel_color = rayColor(&ray, world);
            colored_pixels[j][i] = writeColor(&pixel_color);
        }
    }

    return colored_pixels;
}

fn getRay(self: *const Camera, i: usize, j: usize) Ray {
    const pixel_centor = self.pixel00_loc + self.pixel_delta_u * v3(@floatFromInt(i)) + self.pixel_delta_v * v3(@floatFromInt(j));

    const ray_origin = self.centor;
    const ray_direction = pixel_centor - ray_origin;

    return Ray.init(ray_origin, ray_direction);
}

fn rayColor(ray: *const Ray, world: *const HittableList) Color {
    const inf = std.math.inf(f64);

    var rec: HitRecord = undefined;

    // normals-colored world
    if (world.hit(ray, Interval.init(0.0, inf), &rec)) {
        return (rec.normal + v3(1.0)) * v3(0.5);
    }

    const color_start = Color{ 1.0, 1.0, 1.0 };
    const color_end = Color{ 0.5, 0.7, 1.0 };

    const ray_unit_vec = vec.unit(ray.direction);

    // scale `y()` to [0.0, 1.0]
    const a = 0.5 * (ray_unit_vec[1] + 1.0);

    // (1 - a) * start + a * end
    return color_start * v3(1.0 - a) + color_end * v3(a);
}

inline fn writeColor(color: *const Color) i64 {
    const icolor = Vec3(i64){
        @intFromFloat(255.999 * color[2]),
        @intFromFloat(255.999 * color[1]),
        @intFromFloat(255.999 * color[0]),
    };
    return icolor[2] << 16 | icolor[1] << 8 | icolor[0];
}
