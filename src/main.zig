const std = @import("std");
const config = @import("config");

const Vec3 = @import("vec3.zig").Vec3;
const Point = Vec3(f64);
const Color = Vec3(f64);
const Ray = @import("Ray.zig");

// image
const aspect_ratio: f64 = 16.0 / 9.0;

const image_width: u32 = 1920;
const image_height: u32 = blk: {
    const height: u32 = @intFromFloat(@as(f64, @floatFromInt(image_width)) / aspect_ratio);
    break :blk if (height < 1) 1 else height;
};

// camera
const focal_length: f64 = 1.0;

const viewport_height: f64 = 2.0;
const viewport_width: f64 = viewport_height *
    (@as(f64, @floatFromInt(image_width)) / @as(f64, @floatFromInt(image_height)));

const camera_centor: Point = Point.init(.{ 0.0, 0.0, 0.0 });

// viewport edges
const viewport_u: Point = Point.init(.{ viewport_width, 0.0, 0.0 });
const viewport_v: Point = Point.init(.{ 0.0, -viewport_height, 0.0 });

// pixel delta
const pixel_delta_u: Point = viewport_u.div(@floatFromInt(image_width));
const pixel_delta_v: Point = viewport_v.div(@floatFromInt(image_height));

// locations
const viewport_upper_left: Point = camera_centor
    .vsub(&Point.init(.{ 0, 0, focal_length }))
    .vsub(&viewport_u.div(2.0))
    .vsub(&viewport_v.div(2.0));

const pixel00_loc: Point = viewport_upper_left.vadd(&pixel_delta_u.vadd(&pixel_delta_v).mul(0.5));

// sphere
const Sphere = struct {
    centor: Point,
    radius: f64,

    const Self = @This();

    pub fn init(centor: Point, radius: f64) Self {
        return .{
            .centor = centor,
            .radius = radius,
        };
    }
};

pub fn hitSphere(ray: *const Ray, sphere: *const Sphere) f64 {
    const oc = ray.origin.vsub(&sphere.centor);
    const a = ray.direction.dot(&ray.direction);
    const b = 2.0 * oc.dot(&ray.direction);
    const c = oc.dot(&oc) - (sphere.radius * sphere.radius);
    const discriminant = b * b - 4.0 * a * c;

    if (discriminant < 0.0) {
        return -1.0;
    } else {
        // the smallest t
        return (-b - @sqrt(discriminant)) / (2.0 * a);
    }
}

// ray color: a blue-to-white gradient
pub fn rayColor(ray: *const Ray) Color {
    // a red sphere at (0, 0, -1)
    const sphere = Sphere.init(Point.init(.{ 0.0, 0.0, -1.0 }), 0.5);
    const t = hitSphere(ray, &sphere);
    if (t > 0.0) {
        const e = ray.at(t).vsub(&sphere.centor).unit();
        return Color.init(.{
            0.5 * (e.x() + 1.0),
            0.5 * (e.y() + 1.0),
            0.5 * (e.z() + 1.0),
        });
    }

    const color_start = Color.init(.{ 1.0, 1.0, 1.0 });
    const color_end = Color.init(.{ 0.5, 0.7, 1.0 });

    const ray_unit_vec = ray.direction.unit();

    // scale `y()` to [0.0, 1.0]
    const a = 0.5 * (ray_unit_vec.y() + 1.0);

    // (1 - a) * start + a * end
    return color_start.mul(1.0 - a).vadd(&color_end.mul(a));
}

pub fn writeColor(writer: anytype, color: *const Color) !void {
    const icolor = Vec3(u8).init([_]u8{
        @intFromFloat(255.999 * color.x()),
        @intFromFloat(255.999 * color.y()),
        @intFromFloat(255.999 * color.z()),
    });
    try writer.print("{d} {d} {d}\n", .{ icolor.x(), icolor.y(), icolor.z() });
}

pub fn writePPM(writer: anytype) !void {
    try writer.print("P3\n{d} {d}\n255\n", .{ image_width, image_height });

    for (0..image_height) |j| {
        for (0..image_width) |i| {
            const pixel_centor = pixel00_loc
                .vadd(&pixel_delta_u.mul(@floatFromInt(i)))
                .vadd(&pixel_delta_v.mul(@floatFromInt(j)));
            const ray_direction = pixel_centor.vsub(&camera_centor);
            const ray = Ray.init(camera_centor, ray_direction);
            const color = rayColor(&ray);
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
