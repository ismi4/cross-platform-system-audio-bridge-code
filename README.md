# Audio Capture Electron App

This simple Electron app captures system audio and microphone audio on MacOS. This app does not discern between system audio and microphone audio. In the future, we will separate microphone and system audio so that we can identify the primary user.

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

1. The Electron app window will open and you will need to grant permission for the app to access the system audio and microphone audio.
2. Click the "Start Recording" button to begin capturing audio.
3. The app will capture audio for 30 seconds and save it to a file in your "/tmp" folder.
4. If you wish before 30 seconds you can click the stop button.
