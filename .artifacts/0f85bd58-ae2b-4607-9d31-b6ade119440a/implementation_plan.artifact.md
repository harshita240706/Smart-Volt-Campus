# Implementation Plan - ThingSpeak Cloud Integration

This plan transitions the app to use **ThingSpeak** for logging weekly energy savings. This allows the ESP32 to log data directly to the cloud, making it persistent and accessible from any device.

## Proposed Architecture

1.  **Backend**: [ThingSpeak](https://thingspeak.com/)
    - **Field 1**: Real-time Energy Saved (kWh).
    - **Field 2**: Cumulative Daily Savings (Optional).
2.  **ESP32**:
    - Tracks active time for Light and Fan.
    - Calculates Energy Saved: `Saved = Baseline - Actual`.
    - `Actual = (Watts_Light * Minutes_Light + Watts_Fan * Minutes_Fan) / 60 / 1000`.
    - Pushes the current "Saved" value to ThingSpeak every 20 minutes (ThingSpeak free limit is 15s).
3.  **Flutter App**:
    - Fetches the latest feeds from ThingSpeak to display the weekly history.
    - Handles the Bottom Navigation (Home/History) and Theme Toggle.

## User Action Required

To proceed, please set up a ThingSpeak account and channel:
1.  Create a free account at [ThingSpeak.com](https://thingspeak.com/).
2.  **Create a New Channel** named "Smart Volt Campus".
3.  Enable **Field 1** and name it "Energy Saved".
4.  Go to the **API Keys** tab and note down your:
    - **Channel ID**
    - **Write API Key**
    - **Read API Key**

## Open Questions

> [!IMPORTANT]
> To make the calculation accurate, please provide:
> 1. The **Power Rating** (Watts) of your Light and Fan.
> 2. The **Baseline** (Average daily consumption in kWh) you want to compare against.
> *(If unknown, I will use 20W for light, 60W for fan, and 2.0 kWh for baseline as placeholders).*

## Proposed Changes

### [Providers]

#### [MODIFY] [history_provider.dart](file:///D:/Flutter%20projects/smart_volt_campus/lib/providers/history_provider.dart)
- Replace `SharedPreferences` logic with ThingSpeak API calls.
- Fetch the last 7 entries (or entries from the last 7 days) and map them to "Monday" - "Saturday".

#### [MODIFY] [theme_provider.dart](file:///D:/Flutter%20projects/smart_volt_campus/lib/providers/theme_provider.dart)
- No changes needed (it already handles light/dark persistence locally).

---

### [ESP32 Code (Logic)]

I will provide an Arduino sketch that:
- Uses the `ThingSpeak` library.
- Tracks `millis()` to count how many minutes the light and fan are on.
- Calculates savings every few minutes and uploads to ThingSpeak.

## Verification Plan

### Automated Tests
- N/A.

### Manual Verification
1. **Data Upload**: Power on the ESP32, let it run, and check the ThingSpeak "Private View" charts to see if data points appear.
2. **History Tab**: Open the app and verify the History tab displays the data fetched from ThingSpeak.
3. **Theme Toggle**: Verify the sun/moon icon and settings toggle change the app theme instantly.
