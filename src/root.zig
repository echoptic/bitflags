const std = @import("std");
const testing = std.testing;

fn paddingField(comptime signedness: std.builtin.Signedness, comptime bit_count: u16, n: comptime_int) std.builtin.Type.StructField {
    const T = std.meta.Int(signedness, bit_count);
    return std.builtin.Type.StructField{
        .name = std.fmt.comptimePrint("__unused{}", .{n}),
        .type = T,
        .default_value = &@as(T, 0),
        .is_comptime = false,
        .alignment = 0,
    };
}

pub fn Bitflags(comptime T: type) type {
    switch (@typeInfo(T)) {
        .Enum => |enumInfo| {
            switch (@typeInfo(enumInfo.tag_type)) {
                .Int => |intInfo| {
                    const bit_count = intInfo.bits;
                    const signedness = intInfo.signedness;
                    var fields: [bit_count]std.builtin.Type.StructField = undefined;
                    var field_count = 0;
                    var last_bit = 0;
                    inline for (enumInfo.fields) |field| {
                        if (field.value == 0 or
                            @popCount(@as(std.meta.Int(signedness, bit_count), field.value)) > 1)
                        {
                            @compileError("Bitflags does not support fields with bit count other than 1. Change the value of field '" ++
                                field.name ++ "'");
                        }

                        const current_bit = std.math.log2(field.value) + 1;
                        defer {
                            field_count += 1;
                            last_bit = current_bit;
                        }
                        const padding = current_bit - last_bit - 1;

                        if (padding > 0) {
                            fields[field_count] = paddingField(signedness, padding, field_count);
                            field_count += 1;
                        }

                        fields[field_count] = std.builtin.Type.StructField{
                            .name = field.name,
                            .type = bool,
                            .default_value = &false,
                            .is_comptime = false,
                            .alignment = 0,
                        };
                    }

                    const leftover_bits = bit_count - last_bit;
                    if (leftover_bits > 0) {
                        fields[field_count] = paddingField(signedness, leftover_bits, field_count);
                        field_count += 1;
                    }

                    return @Type(.{
                        .Struct = .{
                            .layout = .@"packed",
                            .backing_integer = enumInfo.tag_type,
                            .fields = fields[0..field_count],
                            .decls = &.{},
                            .is_tuple = false,
                        },
                    });
                },
                else => @compileError("Bitflags only supports integer backed enums"),
            }
        },
        else => @compileError("Bitflags only supports enums"),
    }
}

pub fn zeroUnused(flags: anytype) @TypeOf(flags) {
    var result = flags;
    switch (@typeInfo(@TypeOf(flags))) {
        .Struct => |info| {
            inline for (info.fields) |field| {
                switch (@typeInfo(field.type)) {
                    .Int => @field(result, field.name) = 0,
                    else => {},
                }
            }
            return result;
        },
        else => @compileError("Expected a struct, found: " ++ @TypeOf(flags)),
    }
}

test "simple test" {
    const Flags = Bitflags(enum(u8) {
        a = 0b00000001,
        b = 0b00000010,
        c = 0b00010000,
    });

    const flags: Flags = @bitCast(@as(u8, 0b10001));

    try testing.expect(flags.a and !flags.b and flags.c);
}

test zeroUnused {
    const Flags = Bitflags(enum(u8) {
        a = 0b00000001,
        b = 0b00000010,
        c = 0b00010000,
    });

    const flags: Flags = @bitCast(@as(u8, 0b11001));

    try testing.expectEqual(zeroUnused(flags), Flags{ .a = true, .c = true });
}
