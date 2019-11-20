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

var minHeight = -1
var minWidth = -1
var minRefreshRate = -1.0
var minMode = Display.allModes()[0];
var changeToMode = Display.allModes()[0];

for mode in Display.allModes() {
    if minWidth <= mode.width {
        if minHeight <= mode.height  {
            if minRefreshRate <= mode.refreshRate && mode.isUsableForDesktopGUI() {
                minWidth = mode.width
                minHeight = mode.height
                minRefreshRate = mode.refreshRate
                minMode = mode
            }
        }
    }
    
    if 1920 == mode.width {
        if 1080 == mode.height  {
            if 30.1 > mode.refreshRate && 29.9 < mode.refreshRate && mode.isUsableForDesktopGUI() {
                changeToMode = mode
            }
        }
    }
}

if 30.1 > minMode.refreshRate && 29.9 < minMode.refreshRate {
    let display = CGMainDisplayID()
    let config = UnsafeMutablePointer<CGDisplayConfigRef?>.allocate(capacity: 1)
    defer {config.deallocate()}
    CGBeginDisplayConfiguration(config)
    CGConfigureDisplayWithDisplayMode(config.pointee, display, changeToMode, nil)
    CGCompleteDisplayConfiguration(config.pointee, CGConfigureOption.permanently)
    sleep(1)
    CGBeginDisplayConfiguration(config)
    CGConfigureDisplayWithDisplayMode(config.pointee, display, minMode, nil)
    CGCompleteDisplayConfiguration(config.pointee, CGConfigureOption.permanently)
}
