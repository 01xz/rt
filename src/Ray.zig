const Ray = @This();

const std = @import("std");
const vec = @import("vec.zig");
const v3 = vec.v3;

const Vec3 = vec.Vec3;
const Point = Vec3(f64);

origin: Point,
direction: Vec3(f64),

pub fn init(origin: Point, direction: Vec3(f64)) Ray {
    return .{
        .origin = origin,
        .direction = direction,
    };
}

pub fn at(self: *const Ray, t: f64) Vec3(f64) {
    return self.origin + self.direction * v3(t);
}
