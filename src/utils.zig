const rt = @import("rt.zig");
const vec = @import("vec.zig");

const RandomGen = rt.RandomGen;
const Vec3 = rt.Vec3;
const Float = rt.Float;

pub fn getRandom(rng: *RandomGen, comptime T: type) T {
    return switch (@typeInfo(T)) {
        .ComptimeFloat, .Float => rng.random().float(T),
        .ComptimeInt, .Int => return rng.random().int(T),
        else => @compileError("getRandom: " ++ @typeName(T) ++ " is not supported"),
    };
}

inline fn getRandomDoubleInRange(rng: *RandomGen, min: Float, max: Float) Float {
    const rnd = getRandom(rng, Float);
    return rnd * (max - min) + min;
}

inline fn getRandomVec3(rng: *RandomGen) Vec3 {
    return Vec3{ getRandom(rng, Float), getRandom(rng, Float), getRandom(rng, Float) };
}

inline fn getRandomVec3InRange(rng: *RandomGen, min: Float, max: Float) Vec3 {
    return Vec3{
        getRandomDoubleInRange(rng, min, max),
        getRandomDoubleInRange(rng, min, max),
        getRandomDoubleInRange(rng, min, max),
    };
}

inline fn getRandomVec3InUnitCube(rng: *RandomGen) Vec3 {
    return getRandomVec3InRange(rng, -1.0, 1.0);
}

inline fn getRandomVec3InUnitSphere(rng: *RandomGen) Vec3 {
    while (true) {
        const v = getRandomVec3InUnitCube(rng);
        if (vec.dot(v, v) < 1) {
            return v;
        }
    }
}

pub inline fn getRandomUnitVec3(rng: *RandomGen) Vec3 {
    return vec.unit(getRandomVec3InUnitSphere(rng));
}

pub inline fn getRandomOnHemiSphere(rng: *RandomGen, normal: Vec3) Vec3 {
    const v = getRandomUnitVec3(rng);
    if (vec.dot(v, normal) > 0.0) {
        return v;
    } else {
        return -v;
    }
}
