import AudioToolbox
import Foundation

// Audio settings
let sampleRate = 44100.0
let duration = 1.0  // seconds
let frequency = 440.0  // Hz (A4 note)
let amplitude = 0.5

// Calculate total number of frames
let frameCount = UInt32(sampleRate * duration)

// Generate sine wave samples
var samples = [Float](repeating: 0.0, count: Int(frameCount))
for i in 0..<Int(frameCount) {
    let time = Double(i) / sampleRate
    let sample: Float = .init(amplitude * sin(2.0 * .pi * frequency * time))
    if i % 8 == 0 {
        samples[i] = sample + .init(sin(16.0 * .pi * 3 * time))
    } else {
        samples[i] = sample
    }
}

var audioBuffer: AudioBuffer = .init()
withUnsafeMutablePointer(to: &samples) { samplesData in
    audioBuffer = .init(
        mNumberChannels: 1,
        mDataByteSize: .init(frameCount * 4),
        mData: samplesData
    )
}

let bufferList = AudioBufferList(
    mNumberBuffers: 1,
    mBuffers: audioBuffer
)


// Create the audio buffer
var streamBasicDescription: AudioStreamBasicDescription = .init(
    mSampleRate: sampleRate,
    mFormatID: kAudioFormatLinearPCM,
    mFormatFlags: kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked,
    mBytesPerPacket: 4,
    mFramesPerPacket: 1,
    mBytesPerFrame: 4,
    mChannelsPerFrame: 1,
    mBitsPerChannel: 32,
    mReserved: 0
)

var audioQueue: AudioQueueRef?
var status = AudioQueueNewOutput(
    &streamBasicDescription,
    { _, _, _ in },
    nil,
    nil,
    nil,
    0,
    &audioQueue
)

guard status == noErr, let queue = audioQueue else {
    print("Error creating audio queue")
    exit(1)
}

// Create and enqueue buffer
var buffer: AudioQueueBufferRef?
status = AudioQueueAllocateBuffer(queue, UInt32(frameCount * 4), &buffer)
guard status == noErr, let audioBuffer = buffer else {
    print("Error allocating buffer")
    exit(1)
}

audioBuffer.pointee.mAudioDataByteSize = UInt32(frameCount * 4)
memcpy(audioBuffer.pointee.mAudioData, samples, Int(frameCount * 4))

status = AudioQueueEnqueueBuffer(queue, audioBuffer, 0, nil)
guard status == noErr else {
    print("Error enqueuing buffer")
    exit(1)
}

// Start playing
AudioQueueStart(queue, nil)

// Wait for playback to complete
Thread.sleep(forTimeInterval: duration + 0.1)

// Clean up
AudioQueueStop(queue, true)
AudioQueueDispose(queue, true)
