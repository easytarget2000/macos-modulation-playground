import AudioToolbox
import Foundation

final class AudioToolboxModulator : Modulator {

    // MARK: - Configuration

    let sampleRate: Double = 44100.0
    let durationInSec: Double = 5
    let frequency: Double = 440.0
    let amplitude: Double = 0.5

    // MARK: - Implementation

    func playSound() {
        // MARK: - Sample Generation

        let frameCount: Int = .init(sampleRate * durationInSec)

        var samples: [Float] = (0 ..< frameCount).map { frameIndex in
            let time: Double = .init(frameIndex) / sampleRate
            let sample: Float = .init(amplitude * sin(2.0 * .pi * frequency * time))

            return if frameIndex % 8 == 0 {
                .init(time * amplitude * .init(sample))
            } else {
                sample
            }
        }

        // MARK: - Playback Setup

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
        
        AudioQueueStart(queue, nil)

        Thread.sleep(forTimeInterval: durationInSec + 0.1)

        AudioQueueStop(queue, true)
        AudioQueueDispose(queue, true)
    }

}
