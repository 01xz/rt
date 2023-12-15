const Interval = @This();

const std = @import("std");
const rt = @import("rt.zig");

const Float = rt.Float;

const inf = rt.inf;

min: Float = inf,
max: Float = -inf,

pub fn init(min: Float, max: Float) Interval {
    return .{
        .min = min,
        .max = max,
    };
}

pub fn empty() Interval {
    return .{
        .min = inf,
        .max = -inf,
    };
}

pub fn universe() Interval {
    return .{
        .min = -inf,
        .max = inf,
    };
}

pub fn contains(self: *const Interval, t: Float) bool {
    return self.min <= t and t <= self.max;
}

pub fn surrounds(self: *const Interval, t: Float) bool {
    return self.min < t and t < self.max;
}

pub fn clamp(self: *const Interval, t: Float) Float {
    return if (t < self.min) self.min else if (t > self.max) self.max else t;
}
