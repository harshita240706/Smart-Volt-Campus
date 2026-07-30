# Secure Role-Based Login System Implementation Plan

## Goal
Add a login screen to the app to restrict access to the dashboard. The system will distinguish between "Teachers" and "Other Users" based on the password entered, which can be used to limit permissions (e.g., only Teachers can use Manual Override).

## User Review Required
> [!IMPORTANT]
> **Passwords:**
> - **Teachers:** `SVCT123` (Full Access)
> - **Others:** `SVC123` (View-only or Restricted Access)
>
> **Persistence:** I will use `shared_preferences` to keep the user logged in.
>
> **Permission Logic:** I will implement logic to disable the "Manual Override" toggle if the user is logged in as "Other".

## Proposed Changes

### [Frontend] Flutter App

#### [MODIFY] [pubspec.yaml](file:///D:/Flutter_Projects/smart_volt_campus/pubspec.yaml)
- Add `shared_preferences: ^2.2.2`

#### [NEW] `lib/providers/auth_provider.dart`
- Manage `isLoggedIn` state and `userRole` (Teacher vs Other).
- Persistent storage of login state.

#### [NEW] `lib/screens/login_screen.dart`
- Clean, modern UI for entering the password.
- Visual feedback for incorrect passwords.

#### [MODIFY] [main.dart](file:///D:/Flutter_Projects/smart_volt_campus/lib/main.dart)
- Wrap the app in `AuthProvider`.
- Use a `Consumer` to decide between `LoginScreen` and `DashboardScreen`.
- Add a "Logout" option in the settings.

#### [MODIFY] [lib/providers/control_provider.dart](file:///D:/Flutter_Projects/smart_volt_campus/lib/providers/control_provider.dart)
- Update to respect the user role (e.g., blocking `toggleMode` if not a Teacher).

## Verification Plan
1. **Teacher Login:** Enter `SVCT123`, verify Dashboard opens with full control.
2. **Other Login:** Enter `SVC123`, verify Dashboard opens but Manual Override is disabled.
3. **Invalid Login:** Enter wrong password, verify error message shows.
4. **Persistence:** Close app, reopen, verify it stays logged in.
5. **Logout:** Tap logout, verify it returns to Login screen and clears saved state.
