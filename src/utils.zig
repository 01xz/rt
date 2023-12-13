const std = @import("std");

pub fn randomDouble() f64 {
    const RandomGen = std.rand.DefaultPrng;
    var rng = RandomGen.init(@bitCast(std.time.timestamp()));
    return rng.random().float(f64);
}
