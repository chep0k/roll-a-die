# Product Requirements Document (PRD): Roll a Die

**Roll a Die** is a lightweight, native macOS application built with Swift and AppKit. It provides a simple, quick way for users to roll a 6-sided die directly from the macOS menu bar without taking up Dock space or requiring an active main window.

## App

macOS application. The application ensures a single-instance model per user session.

First launch creates the icon: `RollADie.app` initializes the background agent, creates the menu bar icon. <br>
If the icon is removed, launch re-creates the icon: running `RollADie.app` again mounts the menu bar icon back in the menu bar. <br>
On every launch, preview window is displayed.

## Icon

Lives separately from the App on Menu Bar as a distinct UI element.

One click to roll: Rolls the die with a natural, decelerating 8-frame animation ending on a random face (1–6). <br>
Double click menu: Opens a context menu directly below the menu bar icon with an About option (shortcut Control+I) and a Quit option (shortcut Cmd+Q).
About window: displays a window in the center of the screen displaying "2026 {author, hyperlink to their github} | MIT License" and a clickable link to the GitHub source page.
Quit window: shuts down the applicaiton.

## Resource use

Lighweight CPU processing of the die roll and of the UI update. Zero CPU/resource usage when idle.

## Backend Scheme

```text
RollADieApp (NSApplicationDelegate, NSWindowDelegate, NSMenuDelegate)
│
├── 1. NSStatusItem (Menu Bar Icon)
│    ├── Left Click Event -> Timer (doubleClickInterval) -> performRoll() -> animateRollFrame()
│    └── Double Click Event -> Cancel Timer -> NSMenu.popUp()
│          ├── About (Control+I) -> showAboutWindow()
│          └── Quit (Cmd+Q) -> quitApp()
│
├── 2. NSWindow (Preview Window & About Window)
│    ├── Preview Window: Live Dice Face View & Instructions (orderOut on close)
│    └── About Window: "2026 chep0k | MIT License" & GitHub Source Link
│
└── 3. DistributedNotificationCenter (Singleton IPC)
     └── com.mk.RollADie.reopen -> handleExternalReopen() -> showPreviewWindow()
```

### Components Breakdown

1. RollADieApp: The central Cocoa application delegate managing application lifecycle, event routing, status item initialization, and singleton process control.

2. NSStatusItem: The native macOS menu bar status item instance. Listens for user mouse clicks on the menu bar icon, triggers die roll animations on single clicks, and displays the context menu on double clicks.

3. NSWindow (Preview Window): The preview window instance. Displays a large live view of the current die face alongside instruction labels. Intercepts close events to hide itself without terminating the application.

4. DistributedNotificationCenter: The macOS inter-process communication mechanism. Ensures only one instance runs per user session by notifying the primary active app process to re-focus the preview window whenever a secondary app launch occurs.

## Distributed app

Distributed as a compiled macOS `.app` bundle (`RollADie.app`). Packaged in `.dmg` format.
