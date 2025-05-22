// https://github.com/tiehuis/zig-benchmarks-game/blob/master/src/reverse-complement.zig

const std = @import("std");

fn tolower(c: usize) usize {
    return if (c -% 'A' < 26) c | 32 else c;
}

fn toupper(c: usize) usize {
    return if (c -% 'a' < 26) c & 0x5f else c;
}

const pairs = "ATCGGCTAUAMKRYWWSSYRKMVBHDDHBVNN\n\n";
const table = block: {
    var t: [128]u8 = undefined;

    var i: usize = 0;
    while (i < pairs.len) : (i += 2) {
        t[toupper(pairs[i])] = pairs[i + 1];
        t[tolower(pairs[i])] = pairs[i + 1];
    }

    break :block t;
};

fn process(buf: []u8, ifrom: usize, ito: usize) void {
    var from = ifrom + std.mem.indexOfScalar(u8, buf[ifrom..], '\n').? + 1;
    var to = ito;

    const len = to - from;
    const off = 60 - (len % 61);

    if (off != 0) {
        var m = from + 60 - off;
        while (m < to) : (m += 61) {
            // memmove(m + 1, m, off);
            var i: usize = 0;
            var t = buf[m];
            while (i < off) : (i += 1) {
                std.mem.swap(u8, &buf[m + 1 + i], &t);
            }

            buf[m] = '\n';
        }
    }

    to -= 1;
    while (from <= to) : ({
        from += 1;
        to -= 1;
    }) {
        const c = table[buf[from]];
        buf[from] = table[buf[to]];
        buf[to] = c;
    }
}

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
// Prev var allocator = &gpa.allocator;
const allocator = gpa.allocator();

pub fn main() !void {
    var buffered_stdout = std.io.bufferedWriter(std.io.getStdOut().writer());
    defer buffered_stdout.flush() catch unreachable;
    const stdout = buffered_stdout.writer();

    var buffered_stdin = std.io.bufferedReader(std.io.getStdIn().reader());
    const stdin = buffered_stdin.reader();

    const buf = try stdin.readAllAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(buf);

    var to = buf.len - 1;
    while (true) {
        const from = std.mem.lastIndexOfScalar(u8, buf[0..to], '>').?;
        process(buf, from, to);

        if (from == 0) {
            break;
        }

        to = from - 1;
    }

    _ = try stdout.write(buf);
}
