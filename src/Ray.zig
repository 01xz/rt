const Ray = @This();

const std = @import("std");

const Vec3 = @import("vec3.zig").Vec3(f64);

point: Vec3,
direction: Vec3,

pub fn init(point: Vec3, direction: Vec3) Ray {
    return .{
        .point = point,
        .direction = direction,
    };
}

pub fn at(self: *Ray, t: f64) Vec3 {
    return self.point.vadd(&self.direction.mul(t));
}
