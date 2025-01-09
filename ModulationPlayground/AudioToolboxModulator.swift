import AudioToolbox
import Foundation

final class AudioToolboxModulator : Modulator {

    // MARK: - Configuration

    let sampleRate: Double = 44100.0
    let durationInSec: Double = 1
    let frequency: Double = 330.0
    let amplitude: Double = 0.5
    let numberOfChannels: Int = 1
    let bitsPerChannel: Int = 32
    let framesPerPacket: Int = 1

    private lazy var streamBasicDescription: AudioStreamBasicDescription = {
        .init(
            mSampleRate: self.sampleRate,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked,
            mBytesPerPacket: .init(self.bytesPerPacket),
            mFramesPerPacket: .init(self.framesPerPacket),
            mBytesPerFrame: .init(self.bytesPerFrame),
            mChannelsPerFrame: .init(self.numberOfChannels),
            mBitsPerChannel: .init(bitsPerChannel),
            mReserved: 0
        )
    }()

    private var bytesPerPacket: Int {
        self.bitsPerChannel * self.numberOfChannels / 8
    }

    private var bytesPerFrame: Int {
        self.framesPerPacket * self.bytesPerPacket
    }

    private var queue: AudioQueueRef?

    // MARK: - Implementation

    func setUp() throws {
        let initStatus = AudioQueueNewOutput(
            &self.streamBasicDescription,
            { _, _, _ in },
            nil,
            nil,
            nil,
            0,
            &self.queue
        )

        guard initStatus == noErr else {
            print("Error creating audio queue")
            return
        }
    }

    func tearDown() throws {
        guard let queue else {
            return
        }

        AudioQueueStop(queue, true)
        AudioQueueDispose(queue, true)
    }

    func playSound() async throws {
        guard let queue else {
            return
        }

        let frameCount: Int = .init(sampleRate * durationInSec)
        var samples = self.samples(for: frameCount)
        try self.queueSamples(&samples)

        AudioQueueStart(queue, nil)
    }

    private func samples(for count: Int) -> [Float] {
        return (0 ..< count).map { frameIndex in
            let time: Double = .init(frameIndex) / sampleRate
            let sample: Float
            = .init(amplitude * sin(2.0 * .pi * frequency * time))

            return if frameIndex % 8 == 0 {
                .init(time * amplitude * .init(sample))
            } else {
                sample
            }
        }
    }

    private func queueSamples(_ samples: inout [Float]) throws {
        guard let queue else {
            return
        }

        let samplesCount = samples.count

        var audioBuffer: AudioBuffer = .init()
        withUnsafeMutablePointer(to: &samples) { samplesData in
            audioBuffer = .init(
                mNumberChannels: .init(self.numberOfChannels),
                mDataByteSize: .init(samplesCount * self.bytesPerFrame),
                mData: samplesData
            )
        }

        let _: AudioBufferList = .init(
            mNumberBuffers: 1,
            mBuffers: audioBuffer
        )

        // Create and enqueue buffer
        var buffer: AudioQueueBufferRef?
        let allocationStatus = AudioQueueAllocateBuffer(
            queue,
            .init(samplesCount * self.bytesPerFrame),
            &buffer
        )
        guard allocationStatus == noErr, let buffer else {
            print("Error allocating buffer")
            return
        }

        buffer.pointee.mAudioDataByteSize
        = .init(samplesCount * self.bytesPerFrame)

        memcpy(
            buffer.pointee.mAudioData,
            samples,
            Int(samplesCount * self.bytesPerFrame)
        )

        let enqueueStatus = AudioQueueEnqueueBuffer(queue, buffer, 0, nil)
        guard enqueueStatus == noErr else {
            print("Error enqueuing buffer")
            return
        }
    }
}
