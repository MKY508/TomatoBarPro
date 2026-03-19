<p align="center">
<img src="https://raw.githubusercontent.com/ivoronin/TomatoBar/main/TomatoBar/Assets.xcassets/AppIcon.appiconset/icon_128x128%402x.png" width="128" height="128"/>
<p>

<h1 align="center">TomatoBar Pro</h1>
<p align="center">
<img src="https://img.shields.io/github/actions/workflow/status/ivoronin/TomatoBar/main.yml?branch=main"/> <img src="https://img.shields.io/github/downloads/ivoronin/TomatoBar/total"/> <img src="https://img.shields.io/github/v/release/MKY508/TomatoBar?display_name=tag"/>
</p>

<img
  src="https://raw.githubusercontent.com/MKY508/TomatoBar/main/screenshot.png?raw=true"
  alt="Screenshot"
  width="50%"
  align="right"
/>

## Overview

Have you ever heard of Pomodoro? It's a great technique to help you keep track of time and stay on task during your studies or work. Read more about it on <a href="https://en.wikipedia.org/wiki/Pomodoro_Technique">Wikipedia</a>.

TomatoBar Pro is a modernized fork of <a href="https://github.com/ivoronin/TomatoBar">TomatoBar</a> — world's neatest Pomodoro timer for the macOS menu bar. Built on SwiftUI `MenuBarExtra` for macOS 15+, it keeps the original's minimalist philosophy while adding pause/resume, count-up display, and custom sounds.

## What's new in Pro

- **Pause / Resume** — pause the timer mid-session and resume when ready
- **Count-up display** — optional setting to show elapsed time (0:00 → 25:00) instead of countdown
- **Custom sounds** — pick your own audio files for windup, ding, and ticking
  <details><summary>Default sounds (MIT licensed)</summary>
  Three built-in sounds are included:
  - **windup.wav** — spring winding sound at session start
  - **ding.wav** — bell chime at session end
  - **ticking.wav** — clock tick during work sessions
  </details>
- **Shortcuts integration** — AppIntents let you control the timer from Shortcuts.app
- **Modern architecture** — SwiftUI `MenuBarExtra` replaces the legacy `NSPopover` + `NSStatusItem` approach
- **No external state machine dependency** — SwiftState replaced with a lightweight hand-written state machine

## Requirements

- macOS 15.0 (Sequoia) or later

## Installation

Download the latest release from the <a href="https://github.com/MKY508/TomatoBar/releases/latest/">Releases</a> page.

## Integration with other tools
### Event log
TomatoBar Pro logs state transitions in JSON format to `~/Library/Containers/com.github.MKY508.TomatoBarPro/Data/Library/Caches/TomatoBar.log`. Use this data to analyze your productivity and enrich other data sources.
### Starting and stopping the timer
TomatoBar Pro can be controlled using `tomatobarpro://` URLs. To start or stop the timer from the command line, use `open tomatobarpro://startStop`.

## Older versions
TomatoBar Pro requires macOS 15. For older macOS versions, use the original <a href="https://github.com/ivoronin/TomatoBar">TomatoBar</a>.

## Licenses
 - Timer sounds are licensed from buddhabeats
