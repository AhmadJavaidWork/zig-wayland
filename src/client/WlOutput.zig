const std = @import("std");
const Connection = @import("../Connection.zig");
const common = @import("common.zig");

id: u32,

pub const Transform = enum(u8) {
    Normal,
    @"90",
    @"180",
    @"270",
    Flipped,
    Flipped90,
    Flipped180,
    Flipped270,
};
