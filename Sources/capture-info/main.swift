import Foundation
import AVFoundation
import CommandLineKit

struct DeviceVideoFormat : Codable {
    var width: Int32 = 0
    var height: Int32 = 0
    var framerates: [Float64] = []
}

struct DeviceAudioFormat : Codable {
    var sampleRate: Float64 = 0.0
}

struct DeviceItem : Codable {
    var id: String = ""
    var name: String = ""

    var videoFormats: [DeviceVideoFormat]? = []
    var audioFormats: [DeviceAudioFormat]? = []
}

func getVideoFormatInfo(format: AVCaptureDevice.Format) -> DeviceVideoFormat {
    let videoDimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
    
    let framerateRanges = format.videoSupportedFrameRateRanges;
    var framerates: [Float64] = []
    for range in framerateRanges {
        framerates.append(range.maxFrameRate)
    }
    
    return DeviceVideoFormat(width: videoDimensions.width, height: videoDimensions.height, framerates: framerates)
}

func getAudioFormatInfo(format: AVCaptureDevice.Format) -> DeviceAudioFormat {
    let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(format.formatDescription)
    if let asbd = asbd?.pointee {
        return DeviceAudioFormat(sampleRate: asbd.mSampleRate)
    }
    
    return DeviceAudioFormat()
}

let cli = CommandLineKit.CommandLine()
let deviceName = StringOption(shortFlag: "n", longFlag: "name", required: false,
  helpMessage: "filter by device name.")
cli.addOptions(deviceName)

do {
  try cli.parse()
} catch {
  cli.printUsage(error)
  exit(EX_USAGE)
}

let devices = AVCaptureDevice.devices()
var items: [DeviceItem] = []

for device in devices {
    var videoFormats: [DeviceVideoFormat] = []
    var audioFormats: [DeviceAudioFormat] = []
    
    for format in device.formats {
        switch format.mediaType {
        case AVMediaType.video:
            let vfi = getVideoFormatInfo(format: format)
            videoFormats.append(vfi)
        case AVMediaType.audio:
            let afi = getAudioFormatInfo(format: format)
            audioFormats.append(afi)
        default:
            print("unsupported format detected")
            continue
        }
    }
    
    items.append(DeviceItem(
        id: device.modelID,
        name: device.localizedName,
        videoFormats: videoFormats,
        audioFormats: audioFormats)
    )
}

let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted

var json: Data
deviceName.value != nil ?
      (json = try encoder.encode(items.filter{$0.name == deviceName.value})) : (json = try encoder.encode(items))

print(String(data: json, encoding: .utf8)!)




