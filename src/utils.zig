const std = @import("std");
const vec = @import("vec.zig");

const Vec3 = vec.Vec3;

pub const RandomGen = std.rand.DefaultPrng;

pub fn getRandom(rng: *RandomGen, comptime T: type) T {
    return switch (@typeInfo(T)) {
        .ComptimeFloat, .Float => rng.random().float(T),
        .ComptimeInt, .Int => return rng.random().int(T),
        else => @compileError("getRandom: " ++ @typeName(T) ++ " is not supported"),
    };
}

inline fn getRandomDoubleInRange(rng: *RandomGen, min: f64, max: f64) f64 {
    const rnd = getRandom(rng, f64);
    return rnd * (max - min) + min;
}

inline fn getRandomVec3(rng: *RandomGen) Vec3(f64) {
    return Vec3(f64){ getRandom(rng, f64), getRandom(rng, f64), getRandom(rng, f64) };
}

inline fn getRandomVec3InRange(rng: *RandomGen, min: f64, max: f64) Vec3(f64) {
    return Vec3(f64){
        getRandomDoubleInRange(rng, min, max),
        getRandomDoubleInRange(rng, min, max),
        getRandomDoubleInRange(rng, min, max),
    };
}

inline fn getRandomVec3InUnitCube(rng: *RandomGen) Vec3(f64) {
    return getRandomVec3InRange(rng, -1.0, 1.0);
}

inline fn getRandomVec3InUnitSphere(rng: *RandomGen) Vec3(f64) {
    while (true) {
        const v = getRandomVec3InUnitCube(rng);
        if (vec.dot(v, v) < 1) {
            return v;
        }
    }
}

pub inline fn getRandomUnitVec3(rng: *RandomGen) Vec3(f64) {
    return vec.unit(getRandomVec3InUnitSphere(rng));
}

pub inline fn getRandomOnHemiSphere(rng: *RandomGen, normal: Vec3(f64)) Vec3(f64) {
    const v = getRandomUnitVec3(rng);
    if (vec.dot(v, normal) > 0.0) {
        return v;
    } else {
        return -v;
    }
}
