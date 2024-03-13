# bitflags
## Usage
Add this to your `build.zig`:
```zig
const bitflags = b.dependency("bitflags", .{});
exe.root_module.addImport("bitflags", bitflags.module("root"));
```
and this to your source code:
```zig
const bitflags = @import("bitflags");
```
## Example
```zig
const std = @import("std");
const assert = std.debug.assert;
const bitflags = @import("bitflags");

// The `Bitflags` function generates a struct that has all flags and needed padding.
const Flags = bitflags.Bitflags(enum(u8) {
    // The value `a`, at bit position `0`.
    a = 0b00000001,
    // The value `b`, at bit position `1`.
    b = 0b00000010,
    // The value `c`, at bit position `4`.
    c = 0b00010000,
});

pub fn main() !void {
    const flags: Flags = @bitCast(@as(u8, 0b10001));

    // Check which flags are used.
    assert(flags.a and !flags.b and flags.c);

    // You can also check flags like this, but you need to make sure that there are
    // no unspecified bits present in the number or the result won't be correct.
    assert(std.meta.eql(flags, .{ .a = true, .c = true }));

    // If you don't think the input will contain only expected bit flags,
    // you can use `bitflags.zeroUnused` to set all padding fields to 0.
    assert(std.meta.eql(bitflags.zeroUnused(flags), .{ .a = true, .c = true }));
}
```
## Zig Version Support
Currently supported Zig version is the latest master release.
