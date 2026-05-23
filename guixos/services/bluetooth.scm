(define-module (guixos services bluetooth)
  #:use-module (gnu services)
  #:use-module (gnu services base)
  #:use-module (guix gexp)
  #:use-module (guix records)
  #:export (bluetooth-block-service-type
            bluetooth-block-configuration))

(define-record-type* <bluetooth-block-configuration>
  bluetooth-block-configuration make-bluetooth-block-configuration
  bluetooth-block-configuration?
  (vendor-id  bluetooth-block-vendor-id  (default "0e8d"))
  (product-id bluetooth-block-product-id (default "0717")))

(define (bluetooth-block-udev-rule config)
  (list
   (file->udev-rule
    "70-block-internal-bt.rules"
    (mixed-text-file
     "70-block-internal-bt.rules"
     "# Prevent btusb from binding to internal Bluetooth controller\n"
     "ACTION==\"add\", SUBSYSTEM==\"usb\", "
     "ATTR{idVendor}==\"" (bluetooth-block-vendor-id config) "\", "
     "ATTR{idProduct}==\"" (bluetooth-block-product-id config) "\", "
     "ATTR{authorized}=\"0\"\n"))))

(define bluetooth-block-service-type
  (service-type
    (name 'bluetooth-block)
    (extensions
     (list (service-extension udev-service-type
                              bluetooth-block-udev-rule)))
    (default-value (bluetooth-block-configuration))
    (description
     "Block the internal Bluetooth USB device from being authorized.
Useful when the built-in BT controller has driver issues and a USB
dongle is used as a replacement.")))
