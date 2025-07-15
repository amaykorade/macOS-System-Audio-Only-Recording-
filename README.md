macOS Syatem Audio-Only Recorder

A native solution for **recording system audio only** on macOS, bypassing browser limitations. Built with **Swift** and integrated via an **Electron-based GUI shell**.

## Problem Statement

> Most browsers do not allow direct access to system audio for security and privacy reasons.  
> The goal is to record **only system audio** (excluding the microphone) on macOS.
>

## How it Works

### 1. Intall BlackHole
[BlackHole](https://github.com/ExistentialAudio/BlackHole) is a virtual audio driver that captures system audio.

```bash
brew install blackhole-2ch
```
The go to :
  System Setting -> Sound -> Output        and set your output device to BlackHole 2ch


### 2. Run Swift CLI
swiftc main.swift -o record-audio
./record-audio





#### Explanation of Decisions made

 - Bypassing Broswer Limitations: Broswers don't allow direct system audio capture for privacy/security, so we used a native macOS app in Swift.
 - Audio Routing: Used BlackHole virtual audio device to route system audio output as input.
 - AVFoundation: AVAudioEngine is used to capture the system audio and asve it as a .caf file.
 - Electron Bridge: A electron app wraps the swift binary which allows users to click on "start recording" and "stop recording"
 - No Microphone Input: We deliberately set the input to BlackHole to ensure only system audio is captured, excluding the mic.

### Trade-offs and Limitations

- Users must install BlackHole manually and route system audio output to it
- Temporarily users may not hear their own system audio unless they set a multi-output device
- Recording must be done via desktop app, not via browser due to OS restrictions

