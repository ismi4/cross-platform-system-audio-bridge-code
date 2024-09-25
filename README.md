# Audio Capture Electron App

This Electron app demonstrates how to capture system audio and microphone sound on MacOS. At the moment we are not discerning between the two sources.

## Setup

1. Clone this repository or download the source code.
2. Open a terminal/command prompt and navigate to the project directory.
3. Install the required npm packages:
   ```
   npm install
   ```

## Building the Native Audio Capture Modules

1. Open Terminal and navigate to the project directory.
2. Compile the `main.mm` file:
   ```
   clang++ -std=c++11 -ObjC++ main.mm -framework CoreAudio -framework AudioToolbox -framework AVFoundation -framework Foundation -o audio_recorder
   ```

## Running the Electron App

1. Make sure you've built the native audio capture module for your platform.
2. In the terminal/command prompt, run:
   ```
   npm start
   ```

## Usage

1. The Electron app window will open.
2. Click the "Start Recording" button to begin capturing audio.
3. The app will capture audio for 10 seconds and save it to a file in your Documents folder.
4. Check the console output for the exact file location and any error messages.

## Troubleshooting

- On macOS, you will need to grant permission for the app to access the microphone.

## Notes

- The captured audio is saved in a raw format in "/tmp".
