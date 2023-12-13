const std = @import("std");

pub const RandomGen = std.rand.DefaultPrng;

pub fn getRandom(rng: *RandomGen, comptime T: type) T {
    return switch (@typeInfo(T)) {
        .ComptimeFloat, .Float => rng.random().float(T),
        .ComptimeInt, .Int => return rng.random().int(T),
        else => @compileError("getRandom: " ++ @typeName(T) ++ " is not supported"),
    };
}
