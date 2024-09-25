#import <iostream>
#import <AudioToolbox/AudioToolbox.h>
#import <CoreAudio/CoreAudio.h>
#import <AVFoundation/AVFoundation.h>
#import <chrono>

#define NUM_BUFFERS 3
#define BUFFER_SIZE 4096
#define SAMPLE_RATE 44100
#define RECORD_DURATION 10 // Duration in seconds for each file

AudioQueueRef queue;
AudioQueueBufferRef buffers[NUM_BUFFERS];
AudioStreamBasicDescription format;
AudioFileID audioFile;
SInt64 currentPacket = 0;
UInt32 numPacketsToWrite;
std::chrono::steady_clock::time_point startTime;
int fileCounter = 0;

static void CreateNewAudioFile() {
    fileCounter++;
    CFURLRef fileURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
                                                     CFStringCreateWithFormat(NULL, NULL, CFSTR("/tmp/audio_capture_%d.caf"), fileCounter),
                                                     kCFURLPOSIXPathStyle,
                                                     false);
    OSStatus status = AudioFileCreateWithURL(fileURL, kAudioFileCAFType, &format, kAudioFileFlags_EraseFile, &audioFile);
    if (status != noErr) {
        std::cerr << "Error creating audio file: " << status << std::endl;
        exit(1);
    }
    CFRelease(fileURL);
    currentPacket = 0;
    startTime = std::chrono::steady_clock::now();
    std::cout << "Created new audio file: /tmp/audio_capture_" << fileCounter << ".caf" << std::endl;
}

static void HandleInputBuffer(void *inUserData,
                              AudioQueueRef inAQ,
                              AudioQueueBufferRef inBuffer,
                              const AudioTimeStamp *inStartTime,
                              UInt32 inNumPackets,
                              const AudioStreamPacketDescription *inPacketDesc)
{
    if (inNumPackets > 0) {
        OSStatus status = AudioFileWritePackets(audioFile, false, inBuffer->mAudioDataByteSize,
                                                inPacketDesc, currentPacket, &inNumPackets, inBuffer->mAudioData);
        if (status != noErr) {
            std::cerr << "Error writing audio data to file: " << status << std::endl;
        }
        currentPacket += inNumPackets;
        
        auto now = std::chrono::steady_clock::now();
        auto duration = std::chrono::duration_cast<std::chrono::seconds>(now - startTime).count();
        
        if (duration >= RECORD_DURATION) {
            AudioFileClose(audioFile);
            CreateNewAudioFile();
        }
    }
    
    AudioQueueEnqueueBuffer(queue, inBuffer, 0, NULL);
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        std::cout << "Starting audio capture application..." << std::endl;

        // Check and request microphone permission
        std::cout << "Checking microphone permission..." << std::endl;
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
        if (authStatus == AVAuthorizationStatusNotDetermined) {
            std::cout << "Requesting microphone permission..." << std::endl;
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
                if (!granted) {
                    std::cerr << "Microphone access denied by user" << std::endl;
                    exit(1);
                }
                std::cout << "Microphone access granted by user" << std::endl;
                dispatch_semaphore_signal(semaphore);
            }];
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        } else if (authStatus != AVAuthorizationStatusAuthorized) {
            std::cerr << "Microphone access denied (pre-determined)" << std::endl;
            return 1;
        } else {
            std::cout << "Microphone access already authorized" << std::endl;
        }

        // Set up audio format
        std::cout << "Setting up audio format..." << std::endl;
        format.mSampleRate = SAMPLE_RATE;
        format.mFormatID = kAudioFormatLinearPCM;
        format.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
        format.mBitsPerChannel = 16;
        format.mChannelsPerFrame = 2;
        format.mBytesPerPacket = format.mBytesPerFrame = (format.mBitsPerChannel / 8) * format.mChannelsPerFrame;
        format.mFramesPerPacket = 1;

        // Create a new input queue
        std::cout << "Creating audio queue..." << std::endl;
        OSStatus status = AudioQueueNewInput(&format, HandleInputBuffer, NULL, NULL, NULL, 0, &queue);
        if (status != noErr) {
            std::cerr << "Error creating queue: " << status << std::endl;
            return 1;
        }

        // Create the first audio file
        CreateNewAudioFile();

        // Allocate and enqueue buffers
        std::cout << "Allocating and enqueueing buffers..." << std::endl;
        for (int i = 0; i < NUM_BUFFERS; ++i) {
            status = AudioQueueAllocateBuffer(queue, BUFFER_SIZE, &buffers[i]);
            if (status != noErr) {
                std::cerr << "Error allocating buffer " << i << ": " << status << std::endl;
                return 1;
            }
            status = AudioQueueEnqueueBuffer(queue, buffers[i], 0, NULL);
            if (status != noErr) {
                std::cerr << "Error enqueueing buffer " << i << ": " << status << std::endl;
                return 1;
            }
        }

        // Start the queue
        std::cout << "Starting audio queue..." << std::endl;
        status = AudioQueueStart(queue, NULL);
        if (status != noErr) {
            std::cerr << "Error starting queue: " << status << std::endl;
            return 1;
        }

        std::cout << "Audio capture started. Press Enter to stop..." << std::endl;
        std::cin.get();

        // Stop and clean up
        std::cout << "Stopping audio queue..." << std::endl;
        AudioQueueStop(queue, true);
        std::cout << "Disposing audio queue..." << std::endl;
        AudioQueueDispose(queue, true);
        AudioFileClose(audioFile);

        std::cout << "Audio capture stopped." << std::endl;
        std::cout << "Recorded " << fileCounter << " audio files in /tmp/" << std::endl;
    }
    return 0;
}