#+feature dynamic-literals
package atka9ultra
import "core:fmt"
import "core:text/regex"
import "base:builtin"
import "core:strings"
import "core:os"
import "core:sys/posix"
import "core:mem"
import "core:slice"
import "core:c"
import "core:strconv"
import "core:path/filepath"
import "core:flags"
import "core:encoding/json"
import "core:io"
import "base:runtime"
import "libusb"
VID       :: 0x373b
PID       :: 0x101a
PID_8K    :: 0x101b
PID_WIRED    :: 0x1119
INTERFACE :: 1
can_do_more_than_1K := false

open_mouse :: proc(ctx: libusb.Context) -> (dev_handle: libusb.Device_Handle, has_kern_driver: bool, err: libusb.Error) {
    dev: libusb.Device = nil
    devs_raw: [^]libusb.Device = nil 
    count := libusb.get_device_list(ctx, &devs_raw)
    devs := devs_raw[:count]
    for idev in devs {
        desc: libusb.Device_Descriptor = {}
        if libusb.get_device_descriptor(idev, &desc) != .SUCCESS do continue
        if (desc.idProduct == PID || desc.idProduct == PID_8K || desc.idProduct == PID_WIRED) && desc.idVendor == VID {
            dev = idev
            can_do_more_than_1K = desc.idProduct != PID
            break
        }
    } 
    if dev == nil {
        return nil, has_kern_driver, .NO_DEVICE
    }
    dev_handle = nil
    libusb.open(dev, &dev_handle) or_return
    
    has_kern_driver = libusb.kernel_driver_active(dev_handle, INTERFACE) != .SUCCESS
    if has_kern_driver do libusb.detach_kernel_driver(dev_handle, INTERFACE)


    return dev_handle, has_kern_driver, .SUCCESS
}

PollingRate :: enum {
    Hz1000 = 0x1,
    Hz500  = 0x2,
    Hz250  = 0x4,
    Hz125  = 0x8,
    Hz2000 = 0x10,
    Hz4000 = 0x20,
    Hz8000 = 0x40,
}
PerformanceMode :: enum {
    Basic = 0,
    Competetive,
    CompetetiveMax,
}
decode_driver_number :: proc(number: u16) -> int {
    return int(number & 0xFF)
}
encode_driver_number :: proc(number: int) -> u16 {
    number := u16(number)
    res :u16= 0
    res = number & 0xFF
    res |= (0x55 - res) << 8
    return res
}
ctrl_transfer :: proc (dev_handle: libusb.Device_Handle, reqType: u8, req: u8, value: u16, index: u16, data: []u8) -> libusb.Error {
    err := libusb.control_transfer(dev_handle, reqType, req, value, index, slice.as_ptr(data), u16(len(data)), 0)
    if int(err) >= 0 do return nil
    return err
}
interrupt_transfer :: proc(dev_handle: libusb.Device_Handle, endpoint: u8, buf: []u8) -> libusb.Error {
    t := i32(0)
    err := libusb.interrupt_transfer(dev_handle, endpoint, slice.as_ptr(buf), i32(len(buf)), &t, 0) 
    if int(err) >= 0 do return nil
    return err
}
DpiColors :: struct {
    colors: [8]int,
}
CliOptions :: struct {
    polling_rate: int `usage:"Set polling rate(125, 250, 500, 1000, 2000, 4000, 8000)"`,
    hibernation: string `usage:"Set hibernation time(10s, 30s, 50s, 1m, 2m, 15m, 30m)"`,
    key_delay: int `usage:"Set key delay time(0, 1, 2, 4, 8, 15, 20)"`,
    move_sync: int `usage:"Set move synchronization(0, 1)"`,
    angle_snap: int `usage:"Set angle snape(0, 1)"`,
    ripple_correction: int `usage:"Set ripple correction(0, 1)"`,
    query: bool `usage:"Output current mouse state in json"`,
    dpi_color: DpiColors `usage:"Set dpi colors(1=ff00ff)"`,
    perf_mode: PerformanceMode `usage:"Set performance mode"`
} 
InvalidValue :: union {
    string
}
DriverError :: union #shared_nil {
    libusb.Error,
    InvalidValue,
}
Hibernation :: enum {
    S10 = 1,
    S30 = 3,
    S50 = 5,
    M1  = 6,
    M2  = 12,
    M15 = 90,
    M30 = 180,
}
hibernations: map[string]Hibernation = {
    "10s" = .S10,
    "30s" = .S30,
    "50s" = .S50,
    "1m"  = .M1,
    "2m"  = .M2,
    "15m" = .M15,
    "30m" = .M30,
}
hib_to_string :: proc(hib: Hibernation) -> string {
    val := int(hib)
    if val < 6 {
        return fmt.aprintf("%is", val * 10)
    } else {
        return fmt.aprintf("%im", val * 10 / 60)
    }
} 
Query :: struct {
    data: [17]u8,
    variable: [][]u8,
    insert: proc(data: []u8, idx: int, obj: ^json.Object),
}
querries: []Query = {
    Query {
        data = QUERY_CHARGE,
        insert = proc(data: []u8, _: int, obj: ^json.Object) {
            obj["charge"] = i64(data[6])
        }
    },
    Query {
        data = QUERY_POLL,
        insert = proc(data: []u8, _: int, obj: ^json.Object) {
            polls_reverse := map[PollingRate]int {
                .Hz125 = 125,
                .Hz250 = 250,
                .Hz500 = 500,
                .Hz1000 = 1000,
                .Hz2000 = 2000,
                .Hz4000 = 4000,
                .Hz8000 = 8000,
            }    
            obj["polling_rate"] = i64(polls_reverse[PollingRate(decode_driver_number((transmute(^u16)&data[6])^))])
        }
    },
    Query {
        data = QUERY_HIBERNATION, 
        insert = proc(data: []u8, _:int, obj: ^json.Object) {
            obj["hibernation"]       = (hib_to_string(Hibernation(decode_driver_number((transmute(^u16)&data[10])^)) ))
            obj["key_delay"]         = i64(decode_driver_number((transmute(^u16)&data[6])^))
            obj["move_sync"]         = bool(decode_driver_number((transmute(^u16)&data[8])^))
            obj["angle_snap"]        = bool(decode_driver_number((transmute(^u16)&data[12])^))
            obj["ripple_correction"] = bool(decode_driver_number((transmute(^u16)&data[14])^))
        },
    },
    Query {
        data = QUERY_PERF_MODE,
        insert = proc(data: []u8, _:int, obj: ^json.Object) {
            obj["perf_mode"] = fmt.aprint(PerformanceMode(decode_driver_number((transmute(^u16)&data[10])^)))
        }
    },
    Query {
        data = QUERY_DPI_COLOR, 
        variable = [][]u8{
            []u8 { 4, 0x2c, 16, 0x11, }, // idx, val, idx, val ...
            []u8 { 4, 0x34, 16, 0x09, },
            []u8 { 4, 0x3c, 16, 0x01, },
            []u8 { 4, 0x44, 16, 0xf9, },
        },
        insert = proc(data: []u8, idx: int, obj: ^json.Object) {
            if _, ok := obj["dpi_colors"]; !ok {
                obj["dpi_colors"] = json.Array(make([dynamic]json.Value, 8, 8))
            }
            arr := &obj["dpi_colors"]
            ar := &arr.(json.Array)
            ar[idx*2] = fmt.aprintf("%6X", u32((transmute(^u32be)&data[6])^) >> 8)
            ar[idx*2+1] = fmt.aprintf("%6X", u32((transmute(^u32be)&data[10])^) >> 8)
        },
    },
}
QUERY_CHARGE            :: [?]u8{ 0x8, 0x4, 0x0, 0x0, 0x0,  0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x49 }
QUERY_POLL              :: [?]u8{ 0x8, 0x8, 0x0, 0x0, 0x0,  0x6, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x3f }
QUERY_HIBERNATION       :: [?]u8{ 0x8, 0x8, 0x0, 0x0, 0xa9, 0xa, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x92 }
QUERY_KEY_DELAY         :: QUERY_HIBERNATION
QUERY_MOVE_SYNC         :: QUERY_HIBERNATION
QUERY_ANGLE_SNAP        :: QUERY_HIBERNATION
QUERY_RIPPLE_CORRECTION :: QUERY_HIBERNATION
QUERY_DPI_COLOR         :: [?]u8{ 0x8, 0x8, 0x0, 0x0, 0x2c, 0x8, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x11 }
QUERY_PERF_MODE         :: [?]u8{ 0x8, 0x8, 0x0, 0x0, 0xb5, 0x6, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x8a }

query :: proc(mouse: libusb.Device_Handle, data: []u8) -> libusb.Error {
    ctrl_transfer(mouse, 0x21, 0x9, 0x0208, 1, data[:]) or_return
    interrupt_transfer(mouse, 0x82, data[:]) or_return
    return nil
}
set_perf_mode :: proc (mouse: libusb.Device_Handle, mode: PerformanceMode) -> libusb.Error {
    q := QUERY_PERF_MODE
    query(mouse, q[:]) or_return
    q[1] = 7
    q[16] = 0x8c
    (transmute(^u16)&q[10])^ = encode_driver_number(int(mode))
    ctrl_transfer(mouse, 0x21, 0x9, 0x0208, INTERFACE, q[:]) or_return
    buf := [17]u8{}
    interrupt_transfer(mouse, 0x82, buf[:]) or_return
    return nil
}
set_polling_rate :: proc (dev_handle: libusb.Device_Handle, polling_rate: PollingRate) -> libusb.Error {
    payload := QUERY_POLL
    query(dev_handle, payload[:]) or_return
    payload[1] = 7
    payload[16] = 0x41
    (transmute(^u16)&payload[6])^ = encode_driver_number(int(polling_rate))
    ctrl_transfer(dev_handle, 0x21, 0x9, 0x0208, INTERFACE, payload[:]) or_return
    buf := [17]u8{}
    interrupt_transfer(dev_handle, 0x82, buf[:]) or_return
    return nil
}
set_key_delay :: proc(mouse: libusb.Device_Handle, key_delay: int) -> libusb.Error {
    q := QUERY_MOVE_SYNC
    query(mouse, q[:]) or_return
    q[1] = 7
    q[16] = 0xea
    (transmute(^u16)&q[6])^= encode_driver_number(int(key_delay))
    ctrl_transfer(mouse, 0x21, 0x9, 0x0208, INTERFACE, q[:]) or_return
    buf := [17]u8{}
    interrupt_transfer(mouse, 0x82, buf[:]) or_return
    return nil
}
set_move_sync :: proc(mouse: libusb.Device_Handle, move_sync: bool) -> libusb.Error {
    q := QUERY_MOVE_SYNC
    query(mouse, q[:]) or_return
    q[1] = 7
    q[16] = 0xea
    (transmute(^u16)&q[8])^= encode_driver_number(int(move_sync))
    ctrl_transfer(mouse, 0x21, 0x9, 0x0208, INTERFACE, q[:]) or_return
    buf := [17]u8{}
    interrupt_transfer(mouse, 0x82, buf[:]) or_return
    return nil
}
set_angle_snap :: proc(mouse: libusb.Device_Handle, angle_snap: bool) -> libusb.Error {
    q := QUERY_ANGLE_SNAP
    query(mouse, q[:]) or_return
    q[1] = 7
    q[16] = 0xea
    (transmute(^u16)&q[12])^= encode_driver_number(int(angle_snap))
    ctrl_transfer(mouse, 0x21, 0x9, 0x0208, INTERFACE, q[:]) or_return
    buf := [17]u8{}
    interrupt_transfer(mouse, 0x82, buf[:]) or_return
    return nil
}
set_ripple_correction :: proc(mouse: libusb.Device_Handle, ripple_correction: bool) -> libusb.Error {
    q := QUERY_ANGLE_SNAP
    query(mouse, q[:]) or_return
    q[1] = 7
    q[16] = 0xea
    (transmute(^u16)&q[14])^= encode_driver_number(int(ripple_correction))
    ctrl_transfer(mouse, 0x21, 0x9, 0x0208, INTERFACE, q[:]) or_return
    buf := [17]u8{}
    interrupt_transfer(mouse, 0x82, buf[:]) or_return
    return nil
}
set_hibernation :: proc(mouse: libusb.Device_Handle, hibernation: Hibernation) -> libusb.Error {
    q := QUERY_HIBERNATION
    query(mouse, q[:]) or_return
    q[1] = 7
    q[16] = 0xea
    (transmute(^u16)&q[10])^= encode_driver_number(int(hibernation))
    ctrl_transfer(mouse, 0x21, 0x9, 0x0208, INTERFACE, q[:]) or_return
    buf := [17]u8{}
    interrupt_transfer(mouse, 0x82, buf[:]) or_return
    return nil
}
set_dpi_color :: proc(mouse: libusb.Device_Handle, color: u32, idx: int) -> libusb.Error {
    index := idx / 2
    q := QUERY_DPI_COLOR 
    q[4]  = 0x2c + u8(index) * 8
    q[16] = 0x11 - u8(index) * 8
    query(mouse, q[:]) or_return
    q[1]  = 0x7
    q[4]  = 0x2c + u8(index) * 8
    q[16] = 0x68 - u8(index) * 8

    off := 6
    if idx % 2 == 1 do off = 10

    q[off]     = u8((color & 0xFF0000) >> 16)
    q[off + 1] = u8((color & 0x00FF00) >> 8)
    q[off + 2] = u8((color & 0x0000FF))
    q[off + 3] = 0x55 - q[off] - q[off+1] - q[off + 2] 

    ctrl_transfer(mouse, 0x21, 0x9, 0x0208, INTERFACE, q[:]) or_return
    buf := [17]u8{}
    interrupt_transfer(mouse, 0x82, buf[:]) or_return
    return nil
}


driver_main :: proc(opts: CliOptions) -> DriverError {
    ctx := libusb.Context {}
    libusb.init(&ctx)
    mouse, has_kern_driver := open_mouse(ctx) or_return
    defer if has_kern_driver do libusb.attach_kernel_driver(mouse, INTERFACE)

    libusb.claim_interface(mouse, INTERFACE) or_return
    defer libusb.release_interface(mouse, INTERFACE)

    if opts.query {
        obj := json.Object {}
        for &q in querries {
            if len(q.variable) != 0 {
                for v, i in q.variable {
                    vi := 0
                    dat := q.data
                    for vi < len(v) {
                        idx := v[vi]
                        val := v[vi+1]
                        dat[idx] = val
                        vi += 2
                    }
                    ctrl_transfer(mouse, 0x21, 0x9, 0x0208, 1, dat[:]) or_return
                    interrupt_transfer(mouse, 0x82, dat[:]) or_return
                    q.insert(dat[:], i, &obj)
                }
            } else {
                ctrl_transfer(mouse, 0x21, 0x9, 0x0208, 1, q.data[:]) or_return
                interrupt_transfer(mouse, 0x82, q.data[:]) or_return
                q.insert(q.data[:], 0, &obj)
            }
        
        }
        mopts := json.Marshal_Options { pretty = true }
        json.marshal_to_writer(io.to_writer(os.stream_from_handle(os.stdout)), obj, &mopts)
        fmt.println()
    }

    if opts.polling_rate != 0 {
        polls := map[int]PollingRate {
            125  = .Hz125,
            250  = .Hz250,
            500  = .Hz500,
            1000 = .Hz1000,
        }    
        if can_do_more_than_1K {
            polls = map[int]PollingRate {
                125  = .Hz125,
                250  = .Hz250,
                500  = .Hz500,
                1000 = .Hz1000,
                2000 = .Hz2000,
                4000 = .Hz4000,
                8000 = .Hz8000,
            }    
        }
        if poll, ok := polls[opts.polling_rate]; ok {
            set_polling_rate(mouse, poll) or_return
        } else {
            return "polling-rate"
        }
    } 
    if opts.key_delay != -1 {
        valid_delays := []int {0, 1, 2, 4, 8, 15, 20}
        if !slice.contains(valid_delays, opts.key_delay) {
            return "key-delay" 
        }
        set_key_delay(mouse, opts.key_delay) or_return
    }
    if opts.move_sync != -1 {
        set_move_sync(mouse, opts.move_sync != 0) or_return
    }
    if opts.angle_snap != -1 {
        set_angle_snap(mouse, opts.angle_snap != 0) or_return
    }
    if opts.ripple_correction != -1 {
        set_ripple_correction(mouse, opts.ripple_correction != 0) or_return
    }
    if opts.hibernation != "" {
        if hib, ok := hibernations[opts.hibernation]; ok {
            set_hibernation(mouse, hib)
        } else {
            return "hibernation"
        }
    }
    if int(opts.perf_mode) != -1 {
        set_perf_mode(mouse, opts.perf_mode)
    }
    for color,i in opts.dpi_color.colors {
        if color != -1 {
            set_dpi_color(mouse, u32(color), i) or_return
        }
    }
    return nil
}
dpi_map_type_setter :: proc(
	data: rawptr,
	data_type: typeid,
	unparsed_value: string,
	args_tag: string,
) -> (
	error: string,
	handled: bool,
	alloc_error: runtime.Allocator_Error,
) {
    if data_type == DpiColors {
        handled = true
        iter, err := regex.create_iterator(unparsed_value, "^([0-9])=([0-9A-Fa-f]{6})$")
        defer regex.destroy_iterator(iter)
        set := false
        for r,i in regex.match_iterator(&iter) {
            idx := strconv.atoi(r.groups[1])
            val, _ := strconv.parse_uint(r.groups[2], 16)
            colors := transmute(^DpiColors)data
            colors.colors[idx-1] = int(val)
            set = true
            break
        }
        if !set do error = "expected <dpi_index>=<dpi_color_in_hex>, for example: 1=00ff00"
    }
    return
}
main :: proc () {
    opts: CliOptions = {}
    opts.key_delay         = -1
    opts.move_sync         = -1
    opts.angle_snap        = -1
    opts.ripple_correction = -1
    opts.perf_mode         = PerformanceMode(-1)
    for i in 0..<8 {
        opts.dpi_color.colors[i] = -1
    }
    if len(os.args) == 1 {
        flags.write_usage(os.stream_from_handle(os.stdout), typeid_of(CliOptions), os.args[0], .Unix)
        return
    }
    flags.register_type_setter(dpi_map_type_setter)
    flags.parse_or_exit(&opts, os.args, .Unix)
    err := driver_main(opts)
    if err != nil {
        fmt.eprintln("ERROR:", err)
        os.exit(1)
    }
}

