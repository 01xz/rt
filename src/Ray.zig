const Ray = @This();

const std = @import("std");

const Vec3 = @import("vec3.zig").Vec3(f64);

origin: Vec3,
direction: Vec3,

pub fn init(origin: Vec3, direction: Vec3) Ray {
    return .{
        .origin = origin,
        .direction = direction,
    };
}

pub fn at(self: *Ray, t: f64) Vec3 {
    return self.origin.vadd(&self.direction.mul(t));
}
