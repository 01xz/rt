const Camera = @This();

const std = @import("std");
const hittable = @import("hittable.zig");
const vec3 = @import("vec3.zig");

const Ray = @import("Ray.zig");
const Interval = @import("Interval.zig");
const Allocator = std.mem.Allocator;
const HitRecord = hittable.HitRecord;
const HittableList = hittable.HittableList;
const Vec3 = vec3.Vec3;
const Color = Vec3(f64);
const Point = Vec3(f64);

aspect_ratio: f64,

image_width: u32,
image_height: u32,

centor: Point,

pixel00_loc: Point,

pixel_delta_u: Vec3(f64),
pixel_delta_v: Vec3(f64),

pub fn init(comptime aspect_ratio: f64, comptime image_width: u32) Camera {
    const image_height: u32 = blk: {
        const height: u32 = @intFromFloat(@as(f64, @floatFromInt(image_width)) / aspect_ratio);
        break :blk if (height < 1) 1 else height;
    };

    const focal_length: f64 = 1.0;

    const viewport_height: f64 = 2.0;
    const viewport_width: f64 = viewport_height *
        (@as(f64, @floatFromInt(image_width)) / @as(f64, @floatFromInt(image_height)));

    const centor = Point.at(0, 0, 0);

    // viewport edges
    const viewport_u = Point.at(viewport_width, 0.0, 0.0);
    const viewport_v = Point.at(0.0, -viewport_height, 0.0);

    // pixel delta
    const pixel_delta_u = viewport_u.div(@floatFromInt(image_width));
    const pixel_delta_v = viewport_v.div(@floatFromInt(image_height));

    const viewport_upper_left = centor
        .vsub(&Point.at(0, 0, focal_length))
        .vsub(&viewport_u.div(2.0))
        .vsub(&viewport_v.div(2.0));

    const pixel00_loc = viewport_upper_left.vadd(&pixel_delta_u.vadd(&pixel_delta_v).mul(0.5));

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
            const pixel_centor = self.pixel00_loc
                .vadd(&self.pixel_delta_u.mul(@floatFromInt(i)))
                .vadd(&self.pixel_delta_v.mul(@floatFromInt(j)));
            const ray_direction = pixel_centor.vsub(&self.centor);
            const ray = Ray.init(self.centor, ray_direction);
            const color = rayColor(&ray, world);
            colored_pixels[j][i] = writeColor(&color);
        }
    }

    return colored_pixels;
}

fn rayColor(ray: *const Ray, world: *const HittableList) Color {
    const inf = std.math.inf(f64);

    var rec: HitRecord = undefined;

    // normals-colored world
    if (world.hit(ray, Interval.init(0.0, inf), &rec)) {
        return Color.at(1.0, 1.0, 1.0).vadd(&rec.normal).mul(0.5);
    }

    const color_start = Color.at(1.0, 1.0, 1.0);
    const color_end = Color.at(0.5, 0.7, 1.0);

    const ray_unit_vec = ray.direction.unit();

    // scale `y()` to [0.0, 1.0]
    const a = 0.5 * (ray_unit_vec.y() + 1.0);

    // (1 - a) * start + a * end
    return color_start.mul(1.0 - a).vadd(&color_end.mul(a));
}

inline fn writeColor(color: *const Color) i64 {
    const icolor = Vec3(i64).at(
        @intFromFloat(255.999 * color.x()),
        @intFromFloat(255.999 * color.y()),
        @intFromFloat(255.999 * color.z()),
    );
    return icolor.x() << 16 | icolor.y() << 8 | icolor.z();
}
