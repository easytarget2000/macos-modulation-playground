import AudioToolbox
import Foundation

final class AudioToolboxModulator : Modulator {

    // MARK: - Configuration

    let sampleRate: Double = 44100.0
    let durationInSec: Double = 1
    let frequency: Double = 440.0
    let amplitude: Double = 0.5

    private lazy var streamBasicDescription: AudioStreamBasicDescription = {
        .init(
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
    }()

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
            exit(1)
        }
    }

    func playSound() async throws {
        guard let queue else {
            return
        }

        let frameCount: Int = .init(sampleRate * durationInSec)
        var samples = self.samples(for: frameCount)
        try self.queueSamples(&samples)

        AudioQueueStart(queue, nil)

        try await Task.sleep(for: .seconds(durationInSec))

        AudioQueueStop(queue, true)
        AudioQueueDispose(queue, true)
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
                mNumberChannels: 1,
                mDataByteSize: .init(samplesCount * 4),
                mData: samplesData
            )
        }

        let bufferList = AudioBufferList(
            mNumberBuffers: 1,
            mBuffers: audioBuffer
        )

        // Create and enqueue buffer
        var buffer: AudioQueueBufferRef?
        let allocationStatus = AudioQueueAllocateBuffer(queue, UInt32(samplesCount * 4), &buffer)
        guard allocationStatus == noErr, let audioBuffer = buffer else {
            print("Error allocating buffer")
            return
        }

        audioBuffer.pointee.mAudioDataByteSize = UInt32(samplesCount * 4)
        memcpy(audioBuffer.pointee.mAudioData, samples, Int(samplesCount * 4))

        let enqueueStatus = AudioQueueEnqueueBuffer(queue, audioBuffer, 0, nil)
        guard enqueueStatus == noErr else {
            print("Error enqueuing buffer")
            return
        }
    }
}
