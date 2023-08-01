//
//  AVPlayerItemTrack+Tap.swift
//  IQPlayer Demo
//
//  Created by Iftekhar on 7/25/23.
//

import AVFoundation
import MediaToolbox

extension AVPlayerItemTrack {

    // looks like you can't stop an audio tap synchronously, so it's possible for your clientInfo/tapStorage
    // refCon/cookie object to go out of scope while the tap process callback is still being called.
    // As a solution wrap your object of interest as a weak reference that can be guarded against
    // inside an object (cookie) whose scope we do control.
    private class TapWrapper {
        weak var context: AVPlayerItemTrack?

        init(context: AVPlayerItemTrack) {
            self.context = context
        }
    }

    private struct AssociatedKeys {
        static var audioLevel: Int = 0
        static var audioBuffer: Int = 0
        static var audioFormat: Int = 0
    }

    @objc dynamic private(set) var audioLevel: Float {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.audioLevel) as? Float ?? 0
        }
        set(newValue) {
            objc_setAssociatedObject(self, &AssociatedKeys.audioLevel, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    @objc dynamic private(set) var audioBuffer: AVAudioPCMBuffer? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.audioBuffer) as? AVAudioPCMBuffer
        }
        set(newValue) {
            objc_setAssociatedObject(self, &AssociatedKeys.audioBuffer, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    @objc dynamic private(set) var audioFormat: AVAudioFormat? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.audioFormat) as? AVAudioFormat
        }
        set(newValue) {
            objc_setAssociatedObject(self, &AssociatedKeys.audioFormat, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    // assumes tracks are loaded
    func newAudioMixWithTap() -> AVAudioMix? {

        guard let audioTrack = self.assetTrack else {
            return nil
        }

        let tapInit: MTAudioProcessingTapInitCallback = { (tap, clientInfo, tapStorageOut) in

            // Make tap storage the same as clientInfo. I guess you might want them to be different.
            tapStorageOut.pointee = clientInfo
        }

        let tap_PrepareCallback: MTAudioProcessingTapPrepareCallback = { (tap: MTAudioProcessingTap, maxFrames: CMItemCount, processingFormat: UnsafePointer<AudioStreamBasicDescription>) in

            let wrapper = Unmanaged<TapWrapper>.fromOpaque(MTAudioProcessingTapGetStorage(tap)).takeUnretainedValue()
            wrapper.context?.audioFormat = AVAudioFormat(streamDescription:processingFormat)
        }

        let tapFinalize: MTAudioProcessingTapFinalizeCallback = { (tap) in
            // release wrapper
            Unmanaged<TapWrapper>.fromOpaque(MTAudioProcessingTapGetStorage(tap)).release()
        }

        let tapProcess: MTAudioProcessingTapProcessCallback = { (tap, numberFrames, flags, bufferListInOut, numberFramesOut, flagsOut) in
            let status = MTAudioProcessingTapGetSourceAudio(tap, numberFrames, bufferListInOut, flagsOut, nil, numberFramesOut)
            if noErr != status {
                print("get audio: \(status)\n")
            }

            let wrapper = Unmanaged<TapWrapper>.fromOpaque(MTAudioProcessingTapGetStorage(tap)).takeUnretainedValue()
            guard wrapper.context != nil else {
                return
            }
            
            guard let audioBuffer = UnsafeMutableAudioBufferListPointer(bufferListInOut).first else {
                NSLog("%@", "WARNING: MTAudioTap processing failed with status \(status).")
                return
            }
            let sampleCount = Int(audioBuffer.mDataByteSize) / MemoryLayout<Float>.size
            let samples = UnsafeMutableBufferPointer<Float>(
                start: audioBuffer.mData?.assumingMemoryBound(to: Float.self),
                count: sampleCount)
            guard samples.count > 0 else {
                return
            }

            if let audioFormat = wrapper.context?.audioFormat {
                if #available(iOS 15.0, *) {
                    wrapper.context?.audioBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, bufferListNoCopy: bufferListInOut)
                }
            }

            wrapper.context?.audioLevel = sqrtf(samples.reduce(0) { $0 + powf($1, 2) } / Float(sampleCount))
        }

        let tapWrapper = TapWrapper(context: self)
        let clientInfo = UnsafeMutableRawPointer(Unmanaged.passRetained(tapWrapper).toOpaque())
        var callbacks = MTAudioProcessingTapCallbacks(
            version: kMTAudioProcessingTapCallbacksVersion_0,
            clientInfo: clientInfo,
            init: tapInit,
            finalize: tapFinalize,
            prepare: tap_PrepareCallback,
            unprepare: nil,
            process: tapProcess)

        var tap: Unmanaged<MTAudioProcessingTap>?
        let err = MTAudioProcessingTapCreate(kCFAllocatorDefault, &callbacks, kMTAudioProcessingTapCreationFlag_PostEffects, &tap)
        assert(noErr == err);

        let inputParams = AVMutableAudioMixInputParameters(track: audioTrack)
        inputParams.audioTapProcessor = tap?.takeRetainedValue()

        let audioMix = AVMutableAudioMix()
        audioMix.inputParameters = [inputParams]
        return audioMix
    }
}
