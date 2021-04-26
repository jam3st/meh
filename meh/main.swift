import Foundation

extension CGDirectDisplayID  {
    var displayMode: CGDisplayMode? { CGDisplayCopyDisplayMode(self) }
    func allDisplayModes(options: CFDictionary? = nil) -> [CGDisplayMode] { CGDisplayCopyAllDisplayModes(self, options) as? [CGDisplayMode] ?? [] }
}

struct Display {
    static var main: CGDirectDisplayID { CGMainDisplayID() }
    static var mode: CGDisplayMode? { main.displayMode }
    static func allModes(for directDisplayID: CGDirectDisplayID = main) -> [CGDisplayMode] { directDisplayID.allDisplayModes() }
}

func isDisplayIgfx() -> Bool {
    var isIgfx: Bool = false
    var iterator: io_iterator_t = 0
    let errCode: kern_return_t  = IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching("IOPCIDevice"), &iterator)
    if errCode != kIOReturnSuccess {
        fatalError("Could not retrieve the service dictionary of \"IOPCIDevice\"")
    }

    // iterate over the pci devices
    var device = IOIteratorNext(iterator)
    while device != 0 {
        var unmanagedServiceDictionary: Unmanaged<CFMutableDictionary>?
        if IORegistryEntryCreateCFProperties(device, &unmanagedServiceDictionary, kCFAllocatorDefault, 0) != kIOReturnSuccess {
            IOObjectRelease(device)
            continue
        }
        
        if let serviceDictionary = unmanagedServiceDictionary?.takeRetainedValue() as? [String:Any] {

            if serviceDictionary["AAPL,ig-platform-id"]  != nil {
                if "display" == serviceDictionary["IOName"] as? String {
                    print("Is intel");
                    isIgfx = true
                }
            }
        }

        // release the device
        IOObjectRelease(device)

        // get the next device from the iterator
        device = IOIteratorNext(iterator)
    }
    return isIgfx
}

if isDisplayIgfx() {
   

    var minHeight = -1
    var minWidth = -1
    var minMode = Display.allModes()[0];
    var changeToMode = Display.allModes()[0];

    for mode in Display.allModes() {
        if minWidth <= mode.width {
            if minHeight <= mode.height  {
                if 30.1 > mode.refreshRate && 29.9 < mode.refreshRate && mode.isUsableForDesktopGUI() {
                    minWidth = mode.width
                    minHeight = mode.height
                    minMode = mode
                }
            }
        }
        
        if 60.1 > mode.refreshRate && 59.9 < mode.refreshRate && mode.isUsableForDesktopGUI() {
               changeToMode = mode
        }
    }

    if 30.1 > minMode.refreshRate && 29.9 < minMode.refreshRate {
        let display = CGMainDisplayID()
        let config = UnsafeMutablePointer<CGDisplayConfigRef?>.allocate(capacity: 1)
        defer {config.deallocate()}
        CGBeginDisplayConfiguration(config)
        CGConfigureDisplayWithDisplayMode(config.pointee, display, changeToMode, nil)
        CGCompleteDisplayConfiguration(config.pointee, CGConfigureOption.permanently)
        CGBeginDisplayConfiguration(config)
        CGConfigureDisplayWithDisplayMode(config.pointee, display, minMode, nil)
        CGCompleteDisplayConfiguration(config.pointee, CGConfigureOption.permanently)
    }
}
