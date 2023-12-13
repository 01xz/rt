const Interval = @This();

const std = @import("std");

const inf = std.math.inf(f64);

min: f64 = inf,
max: f64 = -inf,

pub fn init(min: f64, max: f64) Interval {
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

pub fn contains(self: *const Interval, t: f64) bool {
    return self.min <= t and t <= self.max;
}

pub fn surrounds(self: *const Interval, t: f64) bool {
    return self.min < t and t < self.max;
}

pub fn clamp(self: *const Interval, t: f64) f64 {
    return if (t < self.min) self.min else if (t > self.max) self.max else t;
}
