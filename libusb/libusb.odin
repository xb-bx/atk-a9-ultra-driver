package libusb

import "core:c"
import "core:fmt"
//TODO: Make multiplatform
import "core:sys/posix"

//TODO: Probably want to switch this to being statically linked
foreign import lib "system:usb-1.0"

/** \ingroup libusb_desc
 * Device and/or Interface Class codes */
Class_Code :: enum c.int {
	/** In the context of a \ref libusb_device_descriptor "device descriptor",
	 * this bDeviceClass value indicates that each interface specifies its
	 * own class information and all interfaces operate independently.
	 */
	CLASS_PER_INTERFACE       = 0x00,
	/** Audio class */
	CLASS_AUDIO               = 0x01,
	/** Communications class */
	CLASS_COMM                = 0x02,
	/** Human Interface Device class */
	CLASS_HID                 = 0x03,
	/** Physical */
	CLASS_PHYSICAL            = 0x05,
	/** Image class */
	CLASS_IMAGE               = 0x06,
	CLASS_PTP                 = 0x06, /* legacy name from libusb-0.1 usb.h */
	/** Printer class */
	CLASS_PRINTER             = 0x07,
	/** Mass storage class */
	CLASS_MASS_STORAGE        = 0x08,
	/** Hub class */
	CLASS_HUB                 = 0x09,
	/** Data class */
	CLASS_DATA                = 0x0a,
	/** Smart Card */
	CLASS_SMART_CARD          = 0x0b,
	/** Content Security */
	CLASS_CONTENT_SECURITY    = 0x0d,
	/** Video */
	CLASS_VIDEO               = 0x0e,
	/** Personal Healthcare */
	CLASS_PERSONAL_HEALTHCARE = 0x0f,
	/** Diagnostic Device */
	CLASS_DIAGNOSTIC_DEVICE   = 0xdc,
	/** Wireless class */
	CLASS_WIRELESS            = 0xe0,
	/** Miscellaneous class */
	CLASS_MISCELLANEOUS       = 0xef,
	/** Application class */
	CLASS_APPLICATION         = 0xfe,
	/** Class is vendor-specific */
	CLASS_VENDOR_SPEC         = 0xff,
}

/** \ingroup libusb_desc
 * Descriptor types as defined by the USB specification. */
Descriptor_Type :: enum c.int {
	/** Device descriptor. See libusb_device_descriptor. */
	DEVICE                = 0x01,
	/** Configuration descriptor. See libusb_config_descriptor. */
	CONFIG                = 0x02,
	/** String descriptor */
	STRING                = 0x03,
	/** Interface descriptor. See libusb_interface_descriptor. */
	INTERFACE             = 0x04,
	/** Endpoint descriptor. See libusb_endpoint_descriptor. */
	ENDPOINT              = 0x05,
	/** Interface Association Descriptor.
	* See libusb_interface_association_descriptor */
	INTERFACE_ASSOCIATION = 0x0b,
	/** BOS descriptor */
	BOS                   = 0x0f,
	/** Device Capability descriptor */
	DEVICE_CAPABILITY     = 0x10,
	/** HID descriptor */
	HID                   = 0x21,
	/** HID report descriptor */
	REPORT                = 0x22,
	/** Physical descriptor */
	PHYSICAL              = 0x23,
	/** Hub descriptor */
	HUB                   = 0x29,
	/** SuperSpeed Hub descriptor */
	SUPERSPEED_HUB        = 0x2a,
	/** SuperSpeed Endpoint Companion descriptor */
	SS_ENDPOINT_COMPANION = 0x30,
}

/* Descriptor sizes per descriptor type */
DT_DEVICE_SIZE :: 18
DT_CONFIG_SIZE :: 9
DT_INTERFACE_SIZE :: 9
DT_ENDPOINT_SIZE :: 7
DT_ENDPOINT_AUDIO_SIZE :: 9 /* Audio extension */
DT_HUB_NONVAR_SIZE :: 7
DT_SS_ENDPOINT_COMPANION_SIZE :: 6
DT_BOS_SIZE :: 5
DT_DEVICE_CAPABILITY_SIZE :: 3

/* BOS descriptor sizes */
BT_USB_2_0_EXTENSION_SIZE :: 7
BT_SS_USB_DEVICE_CAPABILITY_SIZE :: 10
BT_CONTAINER_ID_SIZE :: 20
BT_PLATFORM_DESCRIPTOR_MIN_SIZE :: 20

/* We unwrap the BOS => define its max size */
DT_BOS_MAX_SIZE :: 42

ENDPOINT_ADDRESS_MASK :: 0x0f /* in bEndpointAddress */
ENDPOINT_DIR_MASK :: 0x80

/** \ingroup libusb_desc
 * Endpoint direction. Values for bit 7 of the
 * \ref libusb_endpoint_descriptor::bEndpointAddress "endpoint address" scheme.
 */
Endpoint_Direction :: enum c.int {
	/** Out: host-to-device */
	ENDPOINT_OUT = 0x00,
	/** In: device-to-host */
	ENDPOINT_IN  = 0x80,
}

TRANSFER_TYPE_MASK :: 0x03 /* in bmAttributes */

/** \ingroup libusb_desc
 * Endpoint transfer type. Values for bits 0:1 of the
 * \ref libusb_endpoint_descriptor::bmAttributes "endpoint attributes" field.
 */
Endpoint_Transfer_Type :: enum c.int {
	/** Control endpoint */
	CONTROL     = 0x0,
	/** Isochronous endpoint */
	ISOCHRONOUS = 0x1,
	/** Bulk endpoint */
	BULK        = 0x2,
	/** Interrupt endpoint */
	INTERRUPT   = 0x3,
}

/** \ingroup libusb_misc
 * Standard requests, as defined in table 9-5 of the USB 3.0 specifications */
Standard_Request :: enum c.int {
	/** Request status of the specific recipient */
	GET_STATUS        = 0x00,
	/** Clear or disable a specific feature */
	CLEAR_FEATURE     = 0x01,

	/* 0x02 is reserved */

	/** Set or enable a specific feature */
	SET_FEATURE       = 0x03,

	/* 0x04 is reserved */

	/** Set device address for all future accesses */
	SET_ADDRESS       = 0x05,
	/** Get the specified descriptor */
	GET_DESCRIPTOR    = 0x06,
	/** Used to update existing descriptors or add new descriptors */
	SET_DESCRIPTOR    = 0x07,
	/** Get the current device configuration value */
	GET_CONFIGURATION = 0x08,
	/** Set device configuration */
	SET_CONFIGURATION = 0x09,
	/** Return the selected alternate setting for the specified interface */
	GET_INTERFACE     = 0x0a,
	/** Select an alternate interface for the specified interface */
	SET_INTERFACE     = 0x0b,
	/** Set then report an endpoint's synchronization frame */
	SYNCH_FRAME       = 0x0c,
	/** Sets both the U1 and U2 Exit Latency */
	SET_SEL           = 0x30,
	/** Delay from the time a host transmits a packet to the time it is
	  * received by the device. */
	SET_ISOCH_DELAY   = 0x31,
}

/** \ingroup libusb_misc
 * Request type bits of the
 * \ref libusb_control_setup::bmRequestType "bmRequestType" field in control
 * transfers. */
Request_Type :: enum c.int {
	/** Standard */
	STANDARD = (0x00 << 5),
	/** Class */
	CLASS    = (0x01 << 5),
	/** Vendor */
	VENDOR   = (0x02 << 5),
	/** Reserved */
	RESERVED = (0x03 << 5),
}

/** \ingroup libusb_misc
 * Recipient bits of the
 * \ref libusb_control_setup::bmRequestType "bmRequestType" field in control
 * transfers. Values 4 through 31 are reserved. */
Request_Recipient :: enum c.int {
	/** Device */
	DEVICE    = 0x00,
	/** Interface */
	INTERFACE = 0x01,
	/** Endpoint */
	ENDPOINT  = 0x02,
	/** Other */
	OTHER     = 0x03,
}

ISO_SYNC_TYPE_MASK :: 0x0c

/** \ingroup libusb_desc
 * Synchronization type for isochronous endpoints. Values for bits 2:3 of the
 * \ref libusb_endpoint_descriptor::bmAttributes "bmAttributes" field in
 * libusb_endpoint_descriptor.
 */
Iso_Sync_Type :: enum c.int {
	/** No synchronization */
	NONE     = 0x0,
	/** Asynchronous */
	ASYNC    = 0x1,
	/** Adaptive */
	ADAPTIVE = 0x2,
	/** Synchronous */
	SYNC     = 0x3,
}

ISO_USAGE_TYPE_MASK :: 0x30

/** \ingroup libusb_desc
 * Usage type for isochronous endpoints. Values for bits 4:5 of the
 * \ref libusb_endpoint_descriptor::bmAttributes "bmAttributes" field in
 * libusb_endpoint_descriptor.
 */
Iso_Usage_Type :: enum c.int {
	/** Data endpoint */
	DATA     = 0x0,
	/** Feedback endpoint */
	FEEDBACK = 0x1,
	/** Implicit feedback Data endpoint */
	IMPLICIT = 0x2,
}

/** \ingroup libusb_desc
 * Supported speeds (wSpeedSupported) bitfield. Indicates what
 * speeds the device supports.
 */
Supported_Speed :: enum c.int {
	/** Low speed operation supported (1.5MBit/s). */
	LOW_SPEED_OPERATION   = (1 << 0),
	/** Full speed operation supported (12MBit/s). */
	FULL_SPEED_OPERATION  = (1 << 1),
	/** High speed operation supported (480MBit/s). */
	HIGH_SPEED_OPERATION  = (1 << 2),
	/** Superspeed operation supported (5000MBit/s). */
	SUPER_SPEED_OPERATION = (1 << 3),
}

/** \ingroup libusb_desc
 * Masks for the bits of the
 * \ref libusb_usb_2_0_extension_descriptor::bmAttributes "bmAttributes" field
 * of the USB 2.0 Extension descriptor.
 */
Usb2_Extension_Attributes :: enum c.int {
	/** Supports Link Power Management (LPM) */
	BM_LPM_SUPPORT = (1 << 1),
}

/** \ingroup libusb_desc
 * Masks for the bits of the
 * \ref libusb_ss_usb_device_capability_descriptor::bmAttributes "bmAttributes" field
 * field of the SuperSpeed USB Device Capability descriptor.
 */
Ss_Usb_Device_Capability_Attributes :: enum c.int {
	/** Supports Latency Tolerance Messages (LTM) */
	BM_LTM_SUPPORT = (1 << 1),
}

/** \ingroup libusb_desc
 * USB capability types
 */
Bos_Type :: enum c.int {
	/** Wireless USB device capability */
	WIRELESS_USB_DEVICE_CAPABILITY = 0x01,
	/** USB 2.0 extensions */
	USB_2_0_EXTENSION              = 0x02,
	/** SuperSpeed USB device capability */
	SS_USB_DEVICE_CAPABILITY       = 0x03,
	/** Container ID type */
	CONTAINER_ID                   = 0x04,
	/** Platform descriptor */
	PLATFORM_DESCRIPTOR            = 0x05,
}

/** \ingroup libusb_desc
 * A structure representing the standard USB device descriptor. This
 * descriptor is documented in section 9.6.1 of the USB 3.0 specification.
 * All multiple-byte fields are represented in host-endian format.
 */
Device_Descriptor :: struct {
	/** Size of this descriptor (in bytes) */
	bLength:            u8,
	/** Descriptor type. Will have value
	 * \ref libusb_descriptor_type::LIBUSB_DT_DEVICE LIBUSB_DT_DEVICE in this
	 * context. */
	bDescriptorType:    u8,
	/** USB specification release number in binary-coded decimal. A value of
	 * 0x0200 indicates USB 2.0, 0x0110 indicates USB 1.1, etc. */
	bcdUSB:             u16,
	/** USB-IF class code for the device. See \ref libusb_class_code. */
	bDeviceClass:       u8,
	/** USB-IF subclass code for the device, qualified by the bDeviceClass
	 * value */
	bDeviceSubClass:    u8,
	/** USB-IF protocol code for the device, qualified by the bDeviceClass and
	 * bDeviceSubClass values */
	bDeviceProtocol:    u8,
	/** Maximum packet size for endpoint 0 */
	bMaxPacketSize0:    u8,
	/** USB-IF vendor ID */
	idVendor:           u16,
	/** USB-IF product ID */
	idProduct:          u16,
	/** Device release number in binary-coded decimal */
	bcdDevice:          u16,
	/** Index of string descriptor describing manufacturer */
	iManufacturer:      u8,
	/** Index of string descriptor describing product */
	iProduct:           u8,
	/** Index of string descriptor containing device serial number */
	iSerialNumber:      u8,
	/** Number of possible configurations */
	bNumConfigurations: u8,
}

/** \ingroup libusb_desc
 * A structure representing the standard USB endpoint descriptor. This
 * descriptor is documented in section 9.6.6 of the USB 3.0 specification.
 * All multiple-byte fields are represented in host-endian format.
 */
Endpoint_Descriptor :: struct {
	/** Size of this descriptor (in bytes) */
	bLength:          u8,
	/** Descriptor type. Will have value
	 * \ref libusb_descriptor_type::LIBUSB_DT_ENDPOINT LIBUSB_DT_ENDPOINT in
	 * this context. */
	bDescriptorType:  u8,
	/** The address of the endpoint described by this descriptor. Bits 0:3 are
	 * the endpoint number. Bits 4:6 are reserved. Bit 7 indicates direction,
	 * see \ref libusb_endpoint_direction. */
	bEndpointAddress: u8,
	/** Attributes which apply to the endpoint when it is configured using
	 * the bConfigurationValue. Bits 0:1 determine the transfer type and
	 * correspond to \ref libusb_endpoint_transfer_type. Bits 2:3 are only used
	 * for isochronous endpoints and correspond to \ref libusb_iso_sync_type.
	 * Bits 4:5 are also only used for isochronous endpoints and correspond to
	 * \ref libusb_iso_usage_type. Bits 6:7 are reserved. */
	bmAttributes:     u8,
	/** Maximum packet size this endpoint is capable of sending/receiving. */
	wMaxPacketSize:   u16,
	/** Interval for polling endpoint for data transfers. */
	bInterval:        u8,
	/** For audio devices only: the rate at which synchronization feedback
	 * is provided. */
	bRefresh:         u8,
	/** For audio devices only: the address if the synch endpoint */
	bSynchAddress:    u8,
	/** Extra descriptors. If libusb encounters unknown endpoint descriptors,
	 * it will store them here, should you wish to parse them. */
	extra:            [^]u8,
	/** Length of the extra descriptors, in bytes. Must be non-negative. */
	extra_length:     c.int,
}

/** \ingroup libusb_desc
 * A structure representing the standard USB interface association descriptor.
 * This descriptor is documented in section 9.6.4 of the USB 3.0 specification.
 * All multiple-byte fields are represented in host-endian format.
 */
Interface_Association_Descriptor :: struct {
	/** Size of this descriptor (in bytes) */
	bLength:           u8,
	/** Descriptor type. Will have value
	* \ref libusb_descriptor_type::LIBUSB_DT_INTERFACE_ASSOCIATION
	* LIBUSB_DT_INTERFACE_ASSOCIATION in this context. */
	bDescriptorType:   u8,
	/** Interface number of the first interface that is associated
	* with this function */
	bFirstInterface:   u8,
	/** Number of contiguous interfaces that are associated with
	* this function */
	bInterfaceCount:   u8,
	/** USB-IF class code for this function.
	* A value of zero is not allowed in this descriptor.
	* If this field is 0xff, the function class is vendor-specific.
	* All other values are reserved for assignment by the USB-IF.
	*/
	bFunctionClass:    u8,
	/** USB-IF subclass code for this function.
	* If this field is not set to 0xff, all values are reserved
	* for assignment by the USB-IF
	*/
	bFunctionSubClass: u8,
	/** USB-IF protocol code for this function.
	* These codes are qualified by the values of the bFunctionClass
	* and bFunctionSubClass fields.
	*/
	bFunctionProtocol: u8,
	/** Index of string descriptor describing this function */
	iFunction:         u8,
}

/** \ingroup libusb_desc
 * Structure containing an array of 0 or more interface association
 * descriptors
 */
Interface_Association_Descriptor_Array :: struct {
	/** Array of interface association descriptors. The size of this array
	 * is determined by the length field.
	 */
	iad:    [^]Interface_Association_Descriptor,
	/** Number of interface association descriptors contained. Read-only. */
	length: c.int,
}

/** \ingroup libusb_desc
 * A structure representing the standard USB interface descriptor. This
 * descriptor is documented in section 9.6.5 of the USB 3.0 specification.
 * All multiple-byte fields are represented in host-endian format.
 */
Interface_Descriptor :: struct {
	/** Size of this descriptor (in bytes) */
	bLength:            u8,
	/** Descriptor type. Will have value
	 * \ref libusb_descriptor_type::LIBUSB_DT_INTERFACE LIBUSB_DT_INTERFACE
	 * in this context. */
	bDescriptorType:    u8,
	/** Number of this interface */
	bInterfaceNumber:   u8,
	/** Value used to select this alternate setting for this interface */
	bAlternateSetting:  u8,
	/** Number of endpoints used by this interface (excluding the control
	 * endpoint). */
	bNumEndpoints:      u8,
	/** USB-IF class code for this interface. See \ref libusb_class_code. */
	bInterfaceClass:    u8,
	/** USB-IF subclass code for this interface, qualified by the
	 * bInterfaceClass value */
	bInterfaceSubClass: u8,
	/** USB-IF protocol code for this interface, qualified by the
	 * bInterfaceClass and bInterfaceSubClass values */
	bInterfaceProtocol: u8,
	/** Index of string descriptor describing this interface */
	iInterface:         u8,
	/** Array of endpoint descriptors. This length of this array is determined
	 * by the bNumEndpoints field. */
	endpoint:           [^]Endpoint_Descriptor,
	/** Extra descriptors. If libusb encounters unknown interface descriptors,
	 * it will store them here, should you wish to parse them. */
	extra:              [^]u8,
	/** Length of the extra descriptors, in bytes. Must be non-negative. */
	extra_length:       c.int,
}

/** \ingroup libusb_desc
 * A collection of alternate settings for a particular USB interface.
 */
Interface :: struct {
	/** Array of interface descriptors. The length of this array is determined
	 * by the num_altsetting field. */
	altsetting:     [^]Interface_Descriptor,
	/** The number of alternate settings that belong to this interface.
	 * Must be non-negative. */
	num_altsetting: c.int,
}

/** \ingroup libusb_desc
 * A structure representing the standard USB configuration descriptor. This
 * descriptor is documented in section 9.6.3 of the USB 3.0 specification.
 * All multiple-byte fields are represented in host-endian format.
 */
Config_Descriptor :: struct {
	/** Size of this descriptor (in bytes) */
	bLength:             u8,
	/** Descriptor type. Will have value
	 * \ref libusb_descriptor_type::LIBUSB_DT_CONFIG LIBUSB_DT_CONFIG
	 * in this context. */
	bDescriptorType:     u8,
	/** Total length of data returned for this configuration */
	wTotalLength:        u16,
	/** Number of interfaces supported by this configuration */
	bNumInterfaces:      u8,
	/** Identifier value for this configuration */
	bConfigurationValue: u8,
	/** Index of string descriptor describing this configuration */
	iConfiguration:      u8,
	/** Configuration characteristics */
	bmAttributes:        u8,
	/** Maximum power consumption of the USB device from this bus in this
	 * configuration when the device is fully operation. Expressed in units
	 * of 2 mA when the device is operating in high-speed mode and in units
	 * of 8 mA when the device is operating in super-speed mode. */
	MaxPower:            u8,
	/** Array of interfaces supported by this configuration. The length of
	 * this array is determined by the bNumInterfaces field. */
	interface:           [^]Interface,
	/** Extra descriptors. If libusb encounters unknown configuration
	 * descriptors, it will store them here, should you wish to parse them. */
	extra:               [^]u8,
	/** Length of the extra descriptors, in bytes. Must be non-negative. */
	extra_length:        c.int,
}

/** \ingroup libusb_desc
 * A structure representing the superspeed endpoint companion
 * descriptor. This descriptor is documented in section 9.6.7 of
 * the USB 3.0 specification. All multiple-byte fields are represented in
 * host-endian format.
 */
Ss_Endpoint_Companion_Descriptor :: struct {
	/** Size of this descriptor (in bytes) */
	bLength:           u8,
	/** Descriptor type. Will have value
	 * \ref libusb_descriptor_type::LIBUSB_DT_SS_ENDPOINT_COMPANION in
	 * this context. */
	bDescriptorType:   u8,
	/** The maximum number of packets the endpoint can send or
	 *  receive as part of a burst. */
	bMaxBurst:         u8,
	/** In bulk EP: bits 4:0 represents the maximum number of
	 *  streams the EP supports. In isochronous EP: bits 1:0
	 *  represents the Mult - a zero based value that determines
	 *  the maximum number of packets within a service interval  */
	bmAttributes:      u8,
	/** The total number of bytes this EP will transfer every
	 *  service interval. Valid only for periodic EPs. */
	wBytesPerInterval: u16,
}

/** \ingroup libusb_desc
 * A generic representation of a BOS Device Capability descriptor. It is
 * advised to check bDevCapabilityType and call the matching
 * libusb_get_*_descriptor function to get a structure fully matching the type.
 */
Bos_Dev_Capability_Descriptor :: struct {
	/** Size of this descriptor (in bytes) */
	bLength:             u8,
	/** Descriptor type. Will have value
	 * \ref libusb_descriptor_type::LIBUSB_DT_DEVICE_CAPABILITY
	 * LIBUSB_DT_DEVICE_CAPABILITY in this context. */
	bDescriptorType:     u8,
	/** Device Capability type */
	bDevCapabilityType:  u8,
	/** Device Capability data (bLength - 3 bytes) */
	dev_capability_data: [0]u8,
}

/** \ingroup libusb_desc
 * A structure representing the Binary Device Object Store (BOS) descriptor.
 * This descriptor is documented in section 9.6.2 of the USB 3.0 specification.
 * All multiple-byte fields are represented in host-endian format.
 */
Bos_Descriptor :: struct {
	/** Size of this descriptor (in bytes) */
	bLength:         u8,
	/** Descriptor type. Will have value
	 * \ref libusb_descriptor_type::LIBUSB_DT_BOS LIBUSB_DT_BOS
	 * in this context. */
	bDescriptorType: u8,
	/** Length of this descriptor and all of its sub descriptors */
	wTotalLength:    u16,
	/** The number of separate device capability descriptors in
	 * the BOS */
	bNumDeviceCaps:  u8,
	/** bNumDeviceCap Device Capability Descriptors
	 * Isochronous packet descriptors, for isochronous transfers only.
	 * This is a C flexible array member and memory must be handled completely manually if it's used.*/
	dev_capability:  [0]^Bos_Dev_Capability_Descriptor,
}

/** \ingroup libusb_desc
 * A structure representing the USB 2.0 Extension descriptor
 * This descriptor is documented in section 9.6.2.1 of the USB 3.0 specification.
 * All multiple-byte fields are represented in host-endian format.
 */
Usb2_Extension_Descriptor :: struct {
	/** Size of this descriptor (in bytes) */
	bLength:            u8,
	/** Descriptor type. Will have value
	 * \ref libusb_descriptor_type::LIBUSB_DT_DEVICE_CAPABILITY
	 * LIBUSB_DT_DEVICE_CAPABILITY in this context. */
	bDescriptorType:    u8,
	/** Capability type. Will have value
	 * \ref libusb_capability_type::LIBUSB_BT_USB_2_0_EXTENSION
	 * LIBUSB_BT_USB_2_0_EXTENSION in this context. */
	bDevCapabilityType: u8,
	/** Bitmap encoding of supported device level features.
	 * A value of one in a bit location indicates a feature is
	 * supported; a value of zero indicates it is not supported.
	 * See \ref libusb_usb_2_0_extension_attributes. */
	bmAttributes:       u32,
}

/** \ingroup libusb_desc
 * A structure representing the SuperSpeed USB Device Capability descriptor
 * This descriptor is documented in section 9.6.2.2 of the USB 3.0 specification.
 * All multiple-byte fields are represented in host-endian format.
 */
Ss_Usb_Device_Capability_Descriptor :: struct {
	/** Size of this descriptor (in bytes) */
	bLength:               u8,
	/** Descriptor type. Will have value
	 * \ref libusb_descriptor_type::LIBUSB_DT_DEVICE_CAPABILITY
	 * LIBUSB_DT_DEVICE_CAPABILITY in this context. */
	bDescriptorType:       u8,
	/** Capability type. Will have value
	 * \ref libusb_capability_type::LIBUSB_BT_SS_USB_DEVICE_CAPABILITY
	 * LIBUSB_BT_SS_USB_DEVICE_CAPABILITY in this context. */
	bDevCapabilityType:    u8,
	/** Bitmap encoding of supported device level features.
	 * A value of one in a bit location indicates a feature is
	 * supported; a value of zero indicates it is not supported.
	 * See \ref libusb_ss_usb_device_capability_attributes. */
	bmAttributes:          u8,
	/** Bitmap encoding of the speed supported by this device when
	 * operating in SuperSpeed mode. See \ref libusb_supported_speed. */
	wSpeedSupported:       u16,
	/** The lowest speed at which all the functionality supported
	 * by the device is available to the user. For example if the
	 * device supports all its functionality when connected at
	 * full speed and above then it sets this value to 1. */
	bFunctionalitySupport: u8,
	/** U1 Device Exit Latency. */
	bU1DevExitLat:         u8,
	/** U2 Device Exit Latency. */
	bU2DevExitLat:         u16,
}

/** \ingroup libusb_desc
 * A structure representing the Container ID descriptor.
 * This descriptor is documented in section 9.6.2.3 of the USB 3.0 specification.
 * All multiple-byte fields, except UUIDs, are represented in host-endian format.
 */
Container_Id_Descriptor :: struct {
	/** Size of this descriptor (in bytes) */
	bLength:            u8,
	/** Descriptor type. Will have value
	 * \ref libusb_descriptor_type::LIBUSB_DT_DEVICE_CAPABILITY
	 * LIBUSB_DT_DEVICE_CAPABILITY in this context. */
	bDescriptorType:    u8,
	/** Capability type. Will have value
	 * \ref libusb_capability_type::LIBUSB_BT_CONTAINER_ID
	 * LIBUSB_BT_CONTAINER_ID in this context. */
	bDevCapabilityType: u8,
	/** Reserved field */
	bReserved:          u8,
	/** 128 bit UUID */
	ContainerID:        u128,
}

/** \ingroup libusb_desc
 * A structure representing a Platform descriptor.
 * This descriptor is documented in section 9.6.2.4 of the USB 3.2 specification.
 * This struct contains a mandatory C flexible array member all of it's memory must be handled completely manually.
 */
Platform_Descriptor :: struct {
	/** Size of this descriptor (in bytes) */
	bLength:                u8,
	/** Descriptor type. Will have value
	 * \ref libusb_descriptor_type::LIBUSB_DT_DEVICE_CAPABILITY
	 * LIBUSB_DT_DEVICE_CAPABILITY in this context. */
	bDescriptorType:        u8,
	/** Capability type. Will have value
	 * \ref libusb_capability_type::LIBUSB_BT_PLATFORM_DESCRIPTOR
	 * LIBUSB_BT_CONTAINER_ID in this context. */
	bDevCapabilityType:     u8,
	/** Reserved field */
	bReserved:              u8,
	/** 128 bit UUID */
	PlatformCapabilityUUID: u128,
	/** Capability data (bLength - 20)
	 * This is a C flexible array member and memory must be handled completely manually.*/
	CapabilityData:         [0]u8,
}

//TODO: Add `libusb_control_setup`

Context :: distinct rawptr
Device :: distinct rawptr
Device_Handle :: distinct rawptr

/** \ingroup libusb_lib
 * Structure providing the version of the libusb runtime
 */
Version :: struct {
	/** Library major version. */
	major:    u16,
	/** Library minor version. */
	minor:    u16,
	/** Library micro version. */
	micro:    u16,
	/** Library nano version. */
	nano:     u16,
	/** Library release candidate suffix string, e.g. "-rc4". */
	rc:       cstring,
	/** For ABI compatibility only. */
	describe: cstring,
}

/** \ingroup libusb_dev
 * Speed codes. Indicates the speed at which the device is operating.
 */
Speed :: enum c.int {
	/** The OS doesn't report or know the device speed. */
	UNKNOWN    = 0,
	/** The device is operating at low speed (1.5MBit/s). */
	LOW        = 1,
	/** The device is operating at full speed (12MBit/s). */
	FULL       = 2,
	/** The device is operating at high speed (480MBit/s). */
	HIGH       = 3,
	/** The device is operating at super speed (5000MBit/s). */
	SUPER      = 4,
	/** The device is operating at super speed plus (10000MBit/s). */
	SUPER_PLUS = 5,
}

/** \ingroup libusb_misc
 * Error codes. Most libusb functions return 0 on success or one of these
 * codes on failure.
 * You can call libusb_error_name() to retrieve a string representation of an
 * error code or libusb_strerror() to get an end-user suitable description of
 * an error code.
 */
Error :: enum c.int {
	/** Success (no error) */
	SUCCESS       = 0,
	/** Input/output error */
	IO            = -1,
	/** Invalid parameter */
	INVALID_PARAM = -2,
	/** Access denied (insufficient permissions) */
	ACCESS        = -3,
	/** No such device (it may have been disconnected) */
	NO_DEVICE     = -4,
	/** Entity not found */
	NOT_FOUND     = -5,
	/** Resource busy */
	BUSY          = -6,
	/** Operation timed out */
	TIMEOUT       = -7,
	/** Overflow */
	OVERFLOW      = -8,
	/** Pipe error */
	PIPE          = -9,
	/** System call interrupted (perhaps due to signal) */
	INTERRUPTED   = -10,
	/** Insufficient memory */
	NO_MEM        = -11,
	/** Operation not supported or unimplemented on this platform */
	NOT_SUPPORTED = -12,
	/* NB: Remember to update LIBUSB_ERROR_COUNT below as well as the
	   message strings in strerror.c when adding new error codes here. */

	/** Other error */
	OTHER         = -99,
}

/* Total number of error codes in enum libusb_error */
ERROR_COUNT :: 14

/** \ingroup libusb_asyncio
 * Transfer type */
TransferType :: enum c.int {
	/** Control transfer */
	CONTROL     = 0,
	/** Isochronous transfer */
	ISOCHRONOUS = 1,
	/** Bulk transfer */
	BULK        = 2,
	/** Interrupt transfer */
	INTERRUPT   = 3,
	/** Bulk stream transfer */
	BULK_STREAM = 4,
}

/** \ingroup libusb_asyncio
 * Transfer status codes */
Transfer_Status :: enum c.int {
	/** Transfer completed without error. Note that this does not indicate
	 * that the entire amount of requested data was transferred. */
	COMPLETED,
	/** Transfer failed */
	ERROR,
	/** Transfer timed out */
	TIMED_OUT,
	/** Transfer was cancelled */
	CANCELLED,
	/** For bulk/interrupt endpoints: halt condition detected (endpoint
	 * stalled). For control endpoints: control request not supported. */
	STALL,
	/** Device was disconnected */
	NO_DEVICE,
	/** Device sent more data than requested */
	OVERFLOW,
}

Transfer_Flag_Bits :: enum u8 {
	/** Report short frames as errors */
	SHORT_NOT_OK,
	/** Automatically free() transfer buffer during libusb_free_transfer().
	 * Note that buffers allocated with libusb_dev_mem_alloc() should not
	 * be attempted freed in this way, since free() is not an appropriate
	 * way to release such memory. */
	FREE_BUFFER,
	/** Automatically call libusb_free_transfer() after callback returns.
	 * If this flag is set, it is illegal to call libusb_free_transfer()
	 * from your transfer callback, as this will result in a double-free
	 * when this flag is acted upon. */
	FREE_TRANSFER,
	/** Terminate transfers that are a multiple of the endpoint's
	 * wMaxPacketSize with an extra zero length packet. This is useful
	 * when a device protocol mandates that each logical request is
	 * terminated by an incomplete packet (i.e. the logical requests are
	 * not separated by other means).
	 *
	 * This flag only affects host-to-device transfers to bulk and interrupt
	 * endpoints. In other situations, it is ignored.
	 *
	 * This flag only affects transfers with a length that is a multiple of
	 * the endpoint's wMaxPacketSize. On transfers of other lengths, this
	 * flag has no effect. Therefore, if you are working with a device that
	 * needs a ZLP whenever the end of the logical request falls on a packet
	 * boundary, then it is sensible to set this flag on <em>every</em>
	 * transfer (you do not have to worry about only setting it on transfers
	 * that end on the boundary).
	 *
	 * This flag is currently only supported on Linux.
	 * On other systems, libusb_submit_transfer() will return
	 * \ref LIBUSB_ERROR_NOT_SUPPORTED for every transfer where this
	 * flag is set.
	 *
	 * Available since libusb-1.0.9.
	 */
	ADD_ZERO_PACKET,
}

Transfer_Flag :: bit_set[Transfer_Flag_Bits;u8]

/** \ingroup libusb_asyncio
 * Isochronous packet descriptor. */
Iso_Packet_Descriptor :: struct {
	/** Length of data to request in this packet */
	length:        c.uint,
	/** Amount of data that was actually transferred */
	actual_length: c.uint,
	/** Status code for this packet */
	status:        Transfer_Status,
}

Transfer_Cb :: #type proc "c" (transfer: ^Transfer)

/** \ingroup libusb_asyncio
 * The generic USB transfer structure. The user populates this structure and
 * then submits it in order to request a transfer. After the transfer has
 * completed, the library populates the transfer with the results and passes
 * it back to the user.
 */
Transfer :: struct {
	/** Handle of the device that this transfer will be submitted to */
	dev_handle:      Device_Handle,
	/** A bitwise OR combination of \ref libusb_transfer_flags. */
	flags:           Transfer_Flag,
	/** Address of the endpoint where this transfer will be sent. */
	endpoint:        u8,
	/** Type of the transfer from \ref libusb_transfer_type */
	type:            u8,
	/** Timeout for this transfer in milliseconds. A value of 0 indicates no
	 * timeout. */
	timeout:         c.uint,
	/** The status of the transfer. Read-only, and only for use within
	 * transfer callback function.
	 *
	 * If this is an isochronous transfer, this field may read COMPLETED even
	 * if there were errors in the frames. Use the
	 * \ref libusb_iso_packet_descriptor::status "status" field in each packet
	 * to determine if errors occurred. */
	status:          Transfer_Status,
	/** Length of the data buffer. Must be non-negative. */
	length:          c.int,
	/** Actual length of data that was transferred. Read-only, and only for
	 * use within transfer callback function. Not valid for isochronous
	 * endpoint transfers. */
	actual_length:   c.int,
	/** Callback function. This will be invoked when the transfer completes,
	 * fails, or is cancelled. */
	callback:        Transfer_Cb,
	/** User context data. Useful for associating specific data to a transfer
	 * that can be accessed from within the callback function.
	 *
	 * This field may be set manually or is taken as the `user_data` parameter
	 * of the following functions:
	 * - libusb_fill_bulk_transfer()
	 * - libusb_fill_bulk_stream_transfer()
	 * - libusb_fill_control_transfer()
	 * - libusb_fill_interrupt_transfer()
	 * - libusb_fill_iso_transfer() */
	user_data:       rawptr,
	/** Data buffer */
	buffer:          [^]u8,
	/** Number of isochronous packets. Only used for I/O with isochronous
	 * endpoints. Must be non-negative. */
	num_iso_packets: c.int,
	/** Isochronous packet descriptors, for isochronous transfers only.
	 * This is a C flexible array member and memory must be handled completely manually if it's used.*/
	iso_packet_desc: [0]Iso_Packet_Descriptor,
}

/** \ingroup libusb_misc
 * Capabilities supported by an instance of libusb on the current running
 * platform. Test if the loaded library supports a given capability by calling
 * \ref libusb_has_capability().
 */
Capability :: enum c.uint {
	/** The libusb_has_capability() API is available. */
	HAS_CAPABILITY                = 0x0000,
	/** Hotplug support is available on this platform. */
	HAS_HOTPLUG                   = 0x0001,
	/** The library can access HID devices without requiring user intervention.
	 * Note that before being able to actually access an HID device, you may
	 * still have to call additional libusb functions such as
	 * \ref libusb_detach_kernel_driver(). */
	HAS_HID_ACCESS                = 0x0100,
	/** The library supports detaching of the default USB driver, using
	 * \ref libusb_detach_kernel_driver(), if one is set by the OS kernel */
	SUPPORTS_DETACH_KERNEL_DRIVER = 0x0101,
}

/** \ingroup libusb_lib
 *  Log message levels.
 */
Log_Level :: enum c.int {
	/** (0) : No messages ever emitted by the library (default) */
	NONE    = 0,
	/** (1) : Error messages are emitted */
	ERROR   = 1,
	/** (2) : Warning and error messages are emitted */
	WARNING = 2,
	/** (3) : Informational, warning and error messages are emitted */
	INFO    = 3,
	/** (4) : All messages are emitted */
	DEBUG   = 4,
}

/** \ingroup libusb_lib
 *  Log callback mode.
 *
 *  Since version 1.0.23, \ref LIBUSB_API_VERSION >= 0x01000107
 *
 * \see libusb_set_log_cb()
 */
Log_Cb_Mode :: enum c.int {
	/** Callback function handling all log messages. */
	GLOBAL  = (1 << 0),
	/** Callback function handling context related log messages. */
	CONTEXT = (1 << 1),
}

/** \ingroup libusb_lib
 * Available option values for libusb_set_option() and libusb_init_context().
 */
Option :: enum c.int {
	/** Set the log message verbosity.
	 *
	 * This option must be provided an argument of type \ref libusb_log_level.
	 * The default level is LIBUSB_LOG_LEVEL_NONE, which means no messages are ever
	 * printed. If you choose to increase the message verbosity level, ensure
	 * that your application does not close the stderr file descriptor.
	 *
	 * You are advised to use level LIBUSB_LOG_LEVEL_WARNING. libusb is conservative
	 * with its message logging and most of the time, will only log messages that
	 * explain error conditions and other oddities. This will help you debug
	 * your software.
	 *
	 * If the LIBUSB_DEBUG environment variable was set when libusb was
	 * initialized, this option does nothing: the message verbosity is fixed
	 * to the value in the environment variable.
	 *
	 * If libusb was compiled without any message logging, this option does
	 * nothing: you'll never get any messages.
	 *
	 * If libusb was compiled with verbose debug message logging, this option
	 * does nothing: you'll always get messages from all levels.
	 */
	LOG_LEVEL           = 0,
	/** Use the UsbDk backend for a specific context, if available.
	 *
	 * This option should be set at initialization with libusb_init_context()
	 * otherwise unspecified behavior may occur.
	 *
	 * Only valid on Windows. Ignored on all other platforms.
	 */
	USE_USBDK           = 1,
	/** Do not scan for devices
	 *
	 * With this option set, libusb will skip scanning devices in
	 * libusb_init_context().
	 *
	 * Hotplug functionality will also be deactivated.
	 *
	 * The option is useful in combination with libusb_wrap_sys_device(),
	 * which can access a device directly without prior device scanning.
	 *
	 * This is typically needed on Android, where access to USB devices
	 * is limited.
	 *
	 * This option should only be used with libusb_init_context()
	 * otherwise unspecified behavior may occur.
	 *
	 * Only valid on Linux. Ignored on all other platforms.
	 */
	NO_DEVICE_DISCOVERY = 2,
	/** Set the context log callback function.
	 *
	 * Set the log callback function either on a context or globally. This
	 * option must be provided an argument of type \ref libusb_log_cb.
	 * Using this option with a NULL context is equivalent to calling
	 * libusb_set_log_cb() with mode \ref LIBUSB_LOG_CB_GLOBAL.
	 * Using it with a non-NULL context is equivalent to calling
	 * libusb_set_log_cb() with mode \ref LIBUSB_LOG_CB_CONTEXT.
	 */
	LOG_CB              = 3,
	MAX                 = 4,
}

Log_Cb :: #type proc "c" (ctx: ^Context, level: Log_Level, str: cstring)

Init_Option_Value :: struct #raw_union {
	ival:          c.int,
	libusb_log_cb: Log_Cb,
}

Init_Option :: struct {
	option: Option,
	value:  Init_Option_Value,
}

/** \ingroup libusb_hotplug
 *
 * Since version 1.0.16, \ref LIBUSB_API_VERSION >= 0x01000102
 *
 * Hotplug events */
Hotplug_Event :: enum c.int {
	/** A device has been plugged in and is ready to use */
	DEVICE_ARRIVED = (1 << 0),
	/** A device has left and is no longer available.
	 * It is the user's responsibility to call libusb_close on any handle associated with a disconnected device.
	 * It is safe to call libusb_get_device_descriptor on a device that has left */
	DEVICE_LEFT    = (1 << 1),
}

/** \ingroup libusb_hotplug
 *
 * Since version 1.0.16, \ref LIBUSB_API_VERSION >= 0x01000102
 *
 * Hotplug flags */
Hotplug_Flag_Bits :: enum c.int {
	/** Arm the callback and fire it for all matching currently attached devices. */
	ENUMERATE = 0,
}

Hotplug_Flag :: bit_set[Hotplug_Flag_Bits; c.int]

/** \ingroup libusb_hotplug
 * Convenience macro when not using any flags */
HOTPLUG_NO_FLAGS :: 0
/** \ingroup libusb_hotplug
 * Wildcard matching for hotplug events */
HOTPLUG_MATCH_ANY :: -1

Hotplug_Callback_Fn :: #type proc "c" (
	ctx: Context,
	device: Device,
	event: Hotplug_Event,
	user_data: rawptr,
) -> c.int
Callback_Handle :: distinct c.int

Transfer_Type :: enum c.int {
	CONTROL     = 0,
	ISOCHRONOUS = 1,
	BULK        = 2,
	INTERRUPT   = 3,
	STREAM      = 4,
}

Poll_Fd :: struct {
	/** Numeric file descriptor */
	fd:     c.int,
	/** Event flags to poll for from <poll.h>. POLLIN indicates that you
	 * should monitor this file descriptor for becoming ready to read from,
	 * and POLLOUT indicates that you should monitor this file descriptor for
	 * nonblocking write readiness. */
	events: posix.Poll_Event,
}

Poll_FD_Added_CB :: #type proc "c" (fd: posix.FD, events: posix.Poll_Event, user_data: rawptr)

Poll_FD_Removed_CB :: #type proc "c" (fd: posix.FD, user_data: rawptr)

@(default_calling_convention = "c", link_prefix = "libusb_")
foreign lib {
	//----- Library initialization/deinitialization ----------------------------------
	set_log_cb :: proc(ctx: Context, cb: Log_Cb, mode: Log_Cb_Mode) ---
	set_option :: proc(ctx: Context, option: Option, args: c.va_list) -> Error ---
	init :: proc(ctx: ^Context) -> Error ---
	init_context :: proc(ctx: ^Context, options: [^]Init_Option, num_options: c.int) -> Error ---
	exit :: proc(ctx: Context) ---

	//----- Device handling and enumeration ----------------------------------
	get_device_list :: proc(ctx: Context, list: ^[^]Device) -> int ---
	free_device_list :: proc(device: [^]Device, unref_devices: c.int) ---
	get_bus_number :: proc(dev: Device) -> u8 ---
	get_port_number :: proc(dev: Device) -> u8 ---
	get_port_numbers :: proc(dev: Device, port_numbers: [^]u8, port_numbers_len: c.int) -> Error ---
	get_parent :: proc(dev: Device) -> Device ---
	get_device_address :: proc(dev: Device) -> u8 ---
	get_device_speed :: proc(dev: Device) -> Speed ---
	get_max_iso_packet_size :: proc(dev: Device, endpoint: c.char) -> c.int ---
	get_max_alt_packet_size :: proc(dev: Device, interface_number: c.int, alternate_setting: c.int, endpoint: u8) -> c.int ---
	ref_device :: proc(dev: Device) -> Device ---
	unref_device :: proc(dev: Device) ---
	wrap_sys_device :: proc(ctx: Context, sys_dev: rawptr, dev_handle: ^Device_Handle) -> Error ---
	open :: proc(dev: Device, dev_handle: ^Device_Handle) -> Error ---
	open_device_with_vid_pid :: proc(ctx: Context, vendor_id: u16, product_id: u16) -> Device_Handle ---
	close :: proc(dev_handle: Device_Handle) ---
	get_device :: proc(dev_handle: Device_Handle) -> Device ---
	get_configuration :: proc(dev: Device_Handle, config: ^c.int) -> Error ---
	set_configuration :: proc(dev_handle: Device_Handle, configuration: c.int) -> Error ---
	claim_interface :: proc(dev_handle: Device_Handle, interface_number: c.int) -> Error ---
	release_interface :: proc(dev_handle: Device_Handle, interface_number: c.int) -> Error ---
	interface_alt_setting :: proc(dev_handle: Device_Handle, interface_number: c.int, alternate_setting: c.int) -> Error ---
	clear_halt :: proc(dev_handle: Device_Handle, endpoint: u8) -> Error ---
	reset_device :: proc(dev_handle: Device_Handle) -> Error ---
	kernel_driver_active :: proc(dev_handle: Device_Handle, interface_number: c.int) -> Error ---
	detach_kernel_driver :: proc(dev_handle: Device_Handle, interface_number: c.int) -> Error ---
	attach_kernel_driver :: proc(dev_handle: Device_Handle, interface_number: c.int) -> Error ---
	set_auto_detach_kernel_driver :: proc(dev_handle: Device_Handle, enable: c.int) -> Error ---

	//----- Miscellaneous ----------------------------------
	has_capability :: proc(capability: Capability) -> c.int ---
	error_name :: proc(errcode: Error) -> cstring ---
	get_version :: proc() -> Version ---
	setlocale :: proc(locale: cstring) -> Error ---
	strerror :: proc(errcode: Error) -> cstring ---

	//----- USB descriptors ----------------------------------
	get_device_descriptor :: proc(dev: Device, desc: ^Device_Descriptor) -> Error ---
	get_active_config_descriptor :: proc(dev: Device, config: ^^Config_Descriptor) -> Error ---
	get_config_descriptor :: proc(dev: Device, config_index: u8, config_descriptor: ^^Config_Descriptor) -> Error ---
	get_config_descriptor_by_value :: proc(dev: Device, bConfigurationValue: u8, config: ^^Config_Descriptor) -> Error ---
	free_config_descriptor :: proc(config: ^Config_Descriptor) ---
	get_ss_endpoint_companion_descriptor :: proc(ctx: Context, endpoint: ^Endpoint_Direction, ep_comp: ^^Ss_Endpoint_Companion_Descriptor) -> Error ---
	free_ss_endpoint_companion_descriptor :: proc(ep_comp: ^Ss_Endpoint_Companion_Descriptor) ---
	get_bos_descriptor :: proc(dev_handle: Device_Handle, bos: ^^Bos_Descriptor) -> Error ---
	free_bos_descriptor :: proc(bos: ^Bos_Descriptor) ---
	get_usb2_extension_descriptor :: proc(ctx: Context, dev_cap: ^Bos_Dev_Capability_Descriptor, usb2_extension: ^^Usb2_Extension_Descriptor) -> Error ---
	free_usb2_extension_descriptor :: proc(usb2_extension: ^Usb2_Extension_Descriptor) ---
	get_ss_usb_device_capability_descriptor :: proc(ctx: Context, dev_cap: ^Bos_Dev_Capability_Descriptor, ss_usb_device_cap: ^^Ss_Usb_Device_Capability_Descriptor) -> Error ---
	free_ss_usb_device_capability_descriptor :: proc(ss_usb_device_cap: ^Ss_Usb_Device_Capability_Descriptor) ---
	get_container_id_descriptor :: proc(ctx: Context, dev_cap: ^Bos_Dev_Capability_Descriptor, container_id: ^^Container_Id_Descriptor) -> Error ---
	free_container_id_descriptor :: proc(container_id: ^Container_Id_Descriptor) ---
	get_platform_descriptor :: proc(ctx: Context, dev_cap: ^Bos_Dev_Capability_Descriptor, platform_descriptor: ^^Platform_Descriptor) -> Error ---
	free_platform_descriptor :: proc(platform_descriptor: ^Platform_Descriptor) ---
	get_string_descriptor_ascii :: proc(dev_handle: Device_Handle, desc_index: u8, data: cstring, length: c.int) -> c.int ---
	get_interface_association_descriptors :: proc(dev: Device, config_index: u8, iad_array: [^][^]Interface_Association_Descriptor_Array) -> Error ---
	get_active_interface_association_descriptors :: proc(dev: Device, iad_array: [^][^]Interface_Association_Descriptor_Array) -> Error ---
	free_interface_association_descriptors :: proc(iad_array: ^Interface_Association_Descriptor_Array) -> Error ---

	//----- Device hotplug event notification ----------------------------------
	hotplug_register_callback :: proc(ctx: Context, events: c.int, flags: Hotplug_Flag, vendor_id: c.int, product_id: c.int, dev_class: c.int, cb_fn: Hotplug_Callback_Fn, user_data: rawptr, callback_handle: ^Callback_Handle) -> Error ---
	hotplug_deregister_callback :: proc(ctx: Context, hotplug_callback_handle: Callback_Handle) ---
	hotplug_get_user_data :: proc(ctx: Context, hotplug_callback_handle: Callback_Handle) -> rawptr ---

	//----- Asynchronous device I/O ----------------------------------
	alloc_streams :: proc(dev_handle: Device_Handle, num_streams: u32, endpoints: [^]u8, num_endpoints: c.int) -> c.int ---
	free_streams :: proc(dev_handle: Device_Handle, endpoints: [^]u8, num_endpoints: c.int) -> Error ---
	dev_mem_alloc :: proc(dev_handle: Device_Handle, length: c.size_t) -> [^]u8 ---
	dev_mem_free :: proc(dev_handle: Device_Handle, buffer: [^]u8, length: c.size_t) -> Error ---
	alloc_transfer :: proc(iso_packets: c.int = 0) -> ^Transfer ---
	free_transfer :: proc(transfer: ^Transfer) ---
	submit_transfer :: proc(transfer: ^Transfer) -> Error ---
	cancel_transfer :: proc(transfer: ^Transfer) -> Error ---
	transfer_set_stream_id :: proc(transfer: ^Transfer, stream_id: u32) ---
	transfer_get_stream_id :: proc(transfer: ^Transfer) -> u32 ---

	//----- Polling and timing ----------------------------------
	try_lock_events :: proc(ctx: Context) -> c.int ---
	lock_events :: proc(ctx: Context) ---
	unlock_events :: proc(ctx: Context) ---
	event_handling_ok :: proc(ctx: Context) -> c.int ---
	event_handler_active :: proc(ctx: Context) -> c.int ---
	interrupt_event_handler :: proc(ctx: Context) ---
	lock_event_waiters :: proc(ctx: Context) ---
	unlock_event_waiters :: proc(ctx: Context) ---
	wait_for_event :: proc(ctx: Context, tv: ^posix.timeval) -> c.int ---
	handle_events_timeout_completed :: proc(ctx: Context, tv: ^posix.timeval, completed: ^c.int) -> Error ---
	handle_events_completed :: proc(ctx: Context, completed: ^c.int) -> Error ---
	handle_events_locked :: proc(ctx: Context, tv: ^posix.timeval) -> Error ---
	pollfds_handle_timeouts :: proc(ctx: Context) -> c.int ---
	get_next_timeout :: proc(ctx: Context, tv: ^posix.timeval) ---
	set_pollfd_notifiers :: proc(ctx: Context, added_cb: Poll_FD_Added_CB, removed_cb: Poll_FD_Removed_CB, user_data: rawptr) ---
	get_pollfds :: proc(ctx: Context) -> [^][^]Poll_Fd ---
	free_fds :: proc(pollfds: [^][^]Poll_Fd) ---

	//----- Synchronous device I/O ----------------------------------
	control_transfer :: proc(dev_handle: Device_Handle, bmRequestType: u8, bRequest: u8, wValue: u16, wIndex: u16, data: [^]u8, wLength: u16, timeout: c.uint) -> Error ---
	bulk_transfer :: proc(dev_handle: Device_Handle, endpoint: u8, data: [^]u8, length: c.int, transferred: ^c.int, timeout: c.uint) -> Error ---
	interrupt_transfer :: proc(dev_handle: Device_Handle, endpoint: u8, data: [^]u8, length: c.int, transferred: ^c.int, timeout: c.uint) -> Error ---
}

// ---------------------------------------------------------------------------------------------------------------------
// ----- Tests ------------------------
// ---------------------------------------------------------------------------------------------------------------------
import "core:testing"

@(test)
init_test :: proc(t: ^testing.T) {
	result := init(nil)

	testing.expect_value(t, result, Error.SUCCESS)
}
