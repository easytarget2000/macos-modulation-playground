import AudioToolbox
import Foundation

final class AudioToolboxModulator : Modulator {

    // MARK: - Configuration

    let sampleRate: Double = 44100.0
    let durationInSec: Double = 1
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
            mBitsPerChannel: .init(self.bitsPerChannel),
            mReserved: 0
        )
    }()

    private var bytesPerPacket: Int {
        (self.bitsPerChannel * self.numberOfChannels) / 8
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

        AudioQueueStop(queue, true)

        let frameCount: Int = .init(
            self.sampleRate * .init(self.numberOfChannels) * self.durationInSec
        )
        let aSamples = self.sineSamples(at: 440, for: frameCount)
        let bSamples = self.sineSamples(at: 880, for: frameCount)
        let combinedSamples = self.combineSamples(aSamples, bSamples)
        try self.queue(samples: combinedSamples)

        AudioQueueStart(queue, nil)
    }

    private func sineSamples(at frequency: Double, for count: Int) -> [Float] {
        return (0 ..< count).map { frameIndex in
            let time: Double
            = .init(frameIndex) / self.sampleRate / .init(self.numberOfChannels)

            return .init(amplitude * sin(2.0 * .pi * frequency * time))
        }
    }

    private func combineSamples(_ a: [Float], _ b: [Float]) -> [Float] {
        guard a.count == b.count else {
            return a
        }

        return zip(a, b).map(+)
    }

    private func queue(samples: [Float]) throws {
        guard let queue else {
            return
        }

        let samplesCount = samples.count
        var samples = samples

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
