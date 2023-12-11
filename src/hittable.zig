const std = @import("std");

const Vec3 = @import("vec3.zig").Vec3;
const Point = Vec3(f64);
const Ray = @import("Ray.zig");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

pub const HitRecord = struct {
    point: Point,
    normal: Vec3(f64),
    t: f64,
    front_face: bool,
};

pub const Hittable = union(enum) {
    sphere: Sphere,

    const Self = @This();

    pub fn hit(self: Self, ray: *const Ray, ray_tmin: f64, ray_tmax: f64, rec: *HitRecord) bool {
        return switch (self) {
            .sphere => |s| s.hit(ray, ray_tmin, ray_tmax, rec),
        };
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

    pub fn hit(self: *const Self, ray: *const Ray, ray_tmin: f64, ray_tmax: f64, rec: *HitRecord) bool {
        var hit_record: HitRecord = undefined;
        var hit_anything: bool = false;
        var closest_so_far: f64 = ray_tmax;

        for (self.objects.items) |object| {
            if (object.hit(ray, ray_tmin, closest_so_far, &hit_record)) {
                hit_anything = true;
                closest_so_far = hit_record.t;
                rec.* = hit_record;
            }
        }

        return hit_anything;
    }
};

pub const Sphere = struct {
    centor: Point,
    radius: f64,

    const Self = @This();

    pub fn init(centor: Point, radius: f64) Self {
        return .{
            .centor = centor,
            .radius = radius,
        };
    }

    pub fn hit(self: *const Self, ray: *const Ray, ray_tmin: f64, ray_tmax: f64, rec: *HitRecord) bool {
        const oc = ray.origin.vsub(&self.centor);

        const a = ray.direction.lenSquared();
        const hb = oc.dot(&ray.direction);
        const c = oc.lenSquared() - (self.radius * self.radius);

        const d = hb * hb - a * c;

        if (d < 0.0) return false;

        const sqrtd = @sqrt(d);

        const root = (-hb - sqrtd) / a;

        // find the nearest root that lies in the acceptable range: (tmin, tmax)
        if (root <= ray_tmin or root >= ray_tmax) {
            const root1 = (-hb + sqrtd) / a;
            if (root1 <= ray_tmin or root1 >= ray_tmax) {
                return false;
            }
        }

        rec.t = root;
        rec.point = ray.at(root);

        const outward_normal = rec.point.vsub(&self.centor).div(self.radius);

        rec.front_face = outward_normal.dot(&ray.direction) < 0.0;

        // always point against the incident ray
        rec.normal = if (rec.front_face) outward_normal else outward_normal.mul(-1.0);

        return true;
    }
};
