const Ray = @This();

const std = @import("std");
const rt = @import("rt.zig");
const vec = @import("vec.zig");

const Vec3 = rt.Vec3;
const Point = rt.Point;
const Float = rt.Float;

const v3 = rt.v3;

origin: Point,
direction: Vec3,

pub fn init(origin: Point, direction: Vec3) Ray {
    return .{
        .origin = origin,
        .direction = direction,
    };
}

pub fn at(self: *const Ray, t: Float) Vec3 {
    return self.origin + self.direction * v3(t);
}
