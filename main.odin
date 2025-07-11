#+feature dynamic-literals
package atka9ultra
import "core:fmt"
import "core:strings"
import "core:os"
import "core:sys/posix"
import "core:mem"
import "core:slice"
import "core:c"
import "core:strconv"
import "core:path/filepath"
import "core:flags"
import "base:runtime"
import "libusb"
VID       :: 0x373b
PID       :: 0x101a
PID_8K    :: 0x101b
INTERFACE :: 1
can_do_more_than_1K := false

wired := false

open_mouse :: proc(ctx: libusb.Context) -> (dev_handle: libusb.Device_Handle, has_kern_driver: bool, err: libusb.Error) {
    dev: libusb.Device = nil
    devs_raw: [^]libusb.Device = nil 
    count := libusb.get_device_list(ctx, &devs_raw)
    devs := devs_raw[:count]
    for idev in devs {
        desc: libusb.Device_Descriptor = {}
        if libusb.get_device_descriptor(idev, &desc) != .SUCCESS do continue
        if (desc.idProduct == PID || desc.idProduct == PID_8K) && desc.idVendor == VID {
            dev = idev
            can_do_more_than_1K = desc.idProduct == PID_8K
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

PollingRate :: enum u16 {
    Hz125   = 0x4d08,
    Hz250   = 0x5104,
    Hz500   = 0x5302,
    Hz1000  = 0x5401,
    Hz2000  = 0x4510,
    Hz4000  = 0x3520,
    Hz8000  = 0x1540,

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

set_polling_rate :: proc (dev_handle: libusb.Device_Handle, polling_rate: PollingRate) -> libusb.Error {
    payload := [?]u8{ 0x08, 0x07, 0x00, 0x00, 0x00, 0x06, 0x08, 0x4d, 0x04, 0x51, 0x03, 0x52, 0x00, 0x00, 0x00, 0x00, 0x41, }; 
    (transmute(^u16)&payload[6])^ = u16(polling_rate)
    ctrl_transfer(dev_handle, 0x21, 0x9, 0x0208, INTERFACE, payload[:]) or_return
    buf := [17]u8{}
    interrupt_transfer(dev_handle, 0x82, buf[:]) or_return
    return nil
}
CliOptions :: struct {
    polling_rate: int `usage:"Set polling rate(125, 250, 500, 1000)"`,
    query_charge: bool `usage:"Output current charge"`,
    query_poll:   bool `usage:"Output current polling rate"`,
} 
DriverError :: union #shared_nil {
    libusb.Error,
    CfgErr,
}
CfgErr :: enum {
    None,
    InvalidPollRate,
}
driver_main :: proc(opts: CliOptions) -> DriverError {
    ctx := libusb.Context {}
    libusb.init(&ctx)
    mouse, has_kern_driver := open_mouse(ctx) or_return
    defer if has_kern_driver do libusb.attach_kernel_driver(mouse, INTERFACE)

    libusb.claim_interface(mouse, INTERFACE) or_return
    defer libusb.release_interface(mouse, INTERFACE)

    polls_reverse := map[PollingRate]int {
        .Hz125 = 125,
        .Hz250 = 250,
        .Hz500 = 500,
        .Hz1000 = 1000,
        .Hz2000 = 2000,
        .Hz4000 = 4000,
        .Hz8000 = 8000,
    }    
    if opts.query_charge {
        charge_data := [?]u8{0x8, 0x4, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x49}
        ctrl_transfer(mouse, 0x21, 0x9, 0x0208, 1, charge_data[:]) or_return
        interrupt_transfer(mouse, 0x82, charge_data[:]) or_return
        fmt.println(charge_data[6])
    } 
    if opts.query_poll {
        poll_data := [?]u8{ 0x8, 0x8, 0x0, 0x0, 0x0, 0x6, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x3f }
        ctrl_transfer(mouse, 0x21, 0x9, 0x0208, 1, poll_data[:]) or_return
        interrupt_transfer(mouse, 0x82, poll_data[:]) or_return
        fmt.println(polls_reverse[(transmute(^PollingRate)&poll_data[6])^])
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
            return .InvalidPollRate
        }
    }
    times := false

    return nil
}
main :: proc () {
    opts: CliOptions = {}
    if len(os.args) == 1 {
        flags.write_usage(os.stream_from_handle(os.stdout), typeid_of(CliOptions), os.args[0], .Unix)
        return
    }
    flags.parse_or_exit(&opts, os.args, .Unix)

    err := driver_main(opts)
    if err != nil {
        fmt.eprintln("ERROR:", err)
        os.exit(1)
    }
}

