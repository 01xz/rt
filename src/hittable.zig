const std = @import("std");
const material = @import("material.zig");
const vec = @import("vec.zig");
const v3 = vec.v3;

const Ray = @import("Ray.zig");
const Interval = @import("Interval.zig");
const Material = material.Material;
const Vec3 = vec.Vec3;
const Point = Vec3(f64);
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

pub const HitRecord = struct {
    point: Point,
    normal: Vec3(f64),
    t: f64,
    front_face: bool,
    mat: Material,
};

pub const Hittable = union(enum) {
    sphere: Sphere,

    const Self = @This();

    pub fn hit(self: Self, ray: *const Ray, ray_t: Interval, rec: *HitRecord) bool {
        return switch (self) {
            .sphere => |s| s.hit(ray, ray_t, rec),
        };
    }

    pub fn sphere(centor: Point, radius: f64, mat: Material) Self {
        return .{ .sphere = Sphere.init(centor, radius, mat) };
    }
};

pub const HittableList = struct {
    objects: ArrayList(Hittable),

    const Self = @This();

    pub fn init(allocator: Allocator) Self {
        return .{
            .objects = ArrayList(Hittable).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.objects.deinit();
    }

    pub fn add(self: *Self, object: Hittable) !void {
        try self.objects.append(object);
    }

    pub fn hit(self: *const Self, ray: *const Ray, ray_t: Interval, rec: *HitRecord) bool {
        var hit_record: HitRecord = undefined;
        var hit_anything: bool = false;
        var closest_so_far: f64 = ray_t.max;

        for (self.objects.items) |object| {
            if (object.hit(ray, Interval.init(ray_t.min, closest_so_far), &hit_record)) {
                hit_anything = true;
                closest_so_far = hit_record.t;
                rec.* = hit_record;
            }
        }

        return hit_anything;
    }
};

const Sphere = struct {
    centor: Point,
    radius: f64,
    mat: Material,

    const Self = @This();

    pub fn init(centor: Point, radius: f64, mat: Material) Self {
        return .{
            .centor = centor,
            .radius = radius,
            .mat = mat,
        };
    }

    pub fn hit(self: *const Self, ray: *const Ray, ray_t: Interval, rec: *HitRecord) bool {
        const oc = ray.origin - self.centor;

        const a = vec.dot(ray.direction, ray.direction);
        const hb = vec.dot(oc, ray.direction);
        const c = vec.dot(oc, oc) - (self.radius * self.radius);

        const d = hb * hb - a * c;

        if (d < 0.0) return false;

        const sqrtd = @sqrt(d);

        const root = (-hb - sqrtd) / a;

        // find the nearest root that lies in the acceptable range: (ray_t.min, ray_t.max)
        if (!ray_t.surrounds(root)) {
            const root1 = (-hb + sqrtd) / a;
            if (!ray_t.surrounds(root1)) {
                return false;
            }
        }

        rec.t = root;
        rec.point = ray.at(root);

        const outward_normal = (rec.point - self.centor) / v3(self.radius);

        rec.front_face = vec.dot(outward_normal, ray.direction) < 0.0;

        // always point against the incident ray
        rec.normal = if (rec.front_face) outward_normal else -outward_normal;

        rec.mat = self.mat;

        return true;
    }
};
