const std = @import("std");
const vec = @import("vec.zig");

pub const RandomGen = std.rand.DefaultPrng;

pub const Vec3 = vec.Vec3(f64);
pub const Color = Vec3;
pub const Point = Vec3;

pub const Float = vec.ChildTypeOf(Vec3);

pub const inf = std.math.inf(Float);

pub const pi: Float = 3.1415926535897932385;

pub inline fn v3(s: Float) Vec3 {
    return vec.fill(Vec3, s);
}
