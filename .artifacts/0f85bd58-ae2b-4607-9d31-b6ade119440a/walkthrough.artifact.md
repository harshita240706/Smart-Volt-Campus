# Walkthrough - Weekly History and Dark Mode

I have successfully added the weekly energy history and the dark mode toggle features to your app.

## Changes Made

### 1. Navigation & UI Structure
- **Bottom Navigation**: Added a bottom bar with "Home" and "History" tabs.
- **Main Wrapper**: Refactored the app to use a navigation wrapper that switches between the Dashboard and the new History screen.

### 2. Weekly History
- **New Screen**: Created `HistoryScreen` which displays the energy saved from Monday to Saturday.
- **Data Persistence**: Implemented `HistoryProvider` using `SharedPreferences` to ensure your data stays saved even if you close the app.
- **Simulation**: Added a "Simulate Energy Saving" button in the History tab so you can test how the data looks when it updates.

### 3. Theme Toggle (Dark/Light Mode)
- **Toggle Button**: Added a moon/sun icon in the top AppBar for quick switching.
- **Settings Toggle**: Added a "Dark Mode" switch inside the Settings bottom sheet.
- **Theme Persistence**: Created `ThemeProvider` to remember your choice (Dark or Light) between sessions.

## How to Test
1. **Switch Tabs**: Tap "History" at the bottom to see your weekly savings.
2. **Simulate Data**: Tap the "Simulate Energy Saving" button in the History tab to add 0.1 kWh to the current day.
3. **Toggle Dark Mode**: Tap the moon/sun icon in the top right or go to Settings to toggle the theme.

> [!TIP]
> Your dark mode preference and history data are automatically saved to your device's memory.
