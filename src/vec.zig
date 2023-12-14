const std = @import("std");

const expectEqual = std.testing.expectEqual;

pub fn Vec3(comptime T: type) type {
    return @Vector(3, T);
}

pub inline fn v3(t: f64) Vec3(f64) {
    return fill(Vec3(f64), t);
}

/// return the size of a vector type `T`
pub inline fn vsize(comptime T: type) comptime_int {
    return @typeInfo(AssertIsTypeVector(T)).Vector.len;
}

test "vector size" {
    try expectEqual(3, vsize(Vec3(i64)));
    try expectEqual(3, vsize(Vec3(f64)));
}

/// return the child type of a vector type `T`
pub inline fn ChildTypeOf(comptime T: type) type {
    return @typeInfo(AssertIsTypeVector(T)).Vector.child;
}

test "child type of vector" {
    try expectEqual(i64, ChildTypeOf(Vec3(i64)));
    try expectEqual(f64, ChildTypeOf(Vec3(f64)));
}

/// fill a specific vector type `T` with `x`
pub fn fill(comptime T: type, x: anytype) T {
    const Tc = ChildTypeOf(AssertIsTypeVector(T));
    const Tx = @TypeOf(x);
    return switch (@typeInfo(Tx)) {
        .ComptimeFloat, .Float, .ComptimeInt, .Int => @splat(@as(Tc, x)),
        else => @compileError("fill: " ++ @typeName(Tx) ++ "is not supported"),
    };
}

test "fill a vector" {
    const va = @Vector(3, i64){ 42, 42, 42 };
    const vb = fill(Vec3(i64), 42);
    try expectEqual(va, vb);
    const vc = @Vector(3, f64){ 42.0, 42.0, 42.0 };
    const vd = fill(Vec3(f64), 42.0);
    try expectEqual(vc, vd);
}

/// dot product of vector `v1` and `v2`
pub fn dot(v1: anytype, v2: anytype) ChildTypeOf(AssertIsTypeVector(@TypeOf(v1))) {
    const Tv1 = AssertIsTypeVector(@TypeOf(v1));
    const Tv2 = AssertIsTypeVector(@TypeOf(v2));
    if (Tv1 != Tv2) {
        @compileError("dot: v1 and v2 must be of the same type");
    }
    return @reduce(.Add, v1 * v2);
}

test "dot product of vector" {
    const v1 = Vec3(f64){ 1.0, 2.0, 3.0 };
    const v2 = Vec3(f64){ 1.0, 5.0, 7.0 };
    const answer: f64 = 32.0;
    try expectEqual(answer, dot(v1, v2));
}

/// cross product of 3-d vector `v1` and `v2`
pub fn cross3(v1: anytype, v2: anytype) AssertIsTypeVector(@TypeOf(v1)) {
    const Tv1 = AssertIsTypeVector(@TypeOf(v1));
    const Tv2 = AssertIsTypeVector(@TypeOf(v2));
    if (Tv1 != Tv2) {
        @compileError("cross3: v1 and v2 must be of the same type");
    }
    if (vsize(Tv1) != 3 or vsize(Tv2) != 3) {
        @compileError("cross3: v1 and v2 must be 3-d vector");
    }
    return Tv1{
        v1[1] * v2[2] - v1[2] * v2[1],
        v1[2] * v2[0] - v1[0] * v2[2],
        v1[0] * v2[1] - v1[1] * v2[0],
    };
}

test "3-d cross product of vector" {
    const v1 = Vec3(f64){ 1.0, 2.0, 3.0 };
    const v2 = Vec3(f64){ 1.0, 5.0, 7.0 };
    try expectEqual(Vec3(f64){ -1.0, -4.0, 3.0 }, cross3(v1, v2));
}

/// length of vector `v`
pub fn vlen(v: anytype) ChildTypeOf(AssertIsTypeVector(@TypeOf(v))) {
    _ = AssertIsTypeVector(@TypeOf(v));
    return @sqrt(dot(v, v));
}

test "length of vector" {
    const v = Vec3(f64){ 3.0, 4.0, 5.0 };
    const answer: f64 = @sqrt(3.0 * 3.0 + 4.0 * 4.0 + 5.0 * 5.0);
    try expectEqual(answer, vlen(v));
}

/// unit vector of the original vector `v`
pub fn unit(v: anytype) AssertIsTypeVector(@TypeOf(v)) {
    return v / fill(@TypeOf(v), vlen(v));
}

test "unit vector" {
    const v = Vec3(f64){ 1.0, 2.0, 3.0 };
    const l = @sqrt(1.0 * 1.0 + 2.0 * 2.0 + 3.0 * 3.0);
    try std.testing.expectEqual(Vec3(f64){ 1.0 / l, 2.0 / l, 3.0 / l }, unit(v));
}

/// make sure T is of type `@Vector`
inline fn AssertIsTypeVector(comptime T: type) type {
    if (@typeInfo(T) != .Vector) {
        @compileError("AssertIsTypeVector: " ++ @typeName(T) ++ " is not a vector");
    }
    return T;
}
