# Workspace Rules for dekstop_tablet_vms

## Read-Only Repositories & Protection Directives
- **`C:\mobile_vms` is STRICTLY READ-ONLY**: Never modify, edit, create, or delete any file in `C:\mobile_vms`. That codebase is live in production/deployment. `C:\mobile_vms` may ONLY be viewed/read for UI & design reference.
- All modifications must strictly be made inside `c:\dekstop_tablet_vms`.

## VMS Operator Tablet Design System Standard

All present and future screens in `dekstop_tablet_vms` must strictly adhere to the following design standards:

### 1. Language Policy
- All UI labels, headers, action buttons, hints, and instructions must be strictly in **English**.

### 2. Color Palette
- **Primary Brand Blue**: `Color(0xFF1976D2)`
- **Dark Brand Blue**: `Color(0xFF0E5DB5)`
- **Tech Accent Blue**: `Color(0xFF0F62FE)`
- **Background Slate Light**: `Color(0xFFF8FAFC)` / `Color(0xFFF4F7FB)`
- **Text Slate Dark**: `Color(0xFF1E293B)`
- **Text Slate Muted**: `Color(0xFF64748B)`
- **Success / Connected Green**: `Color(0xFF10B981)` (Emerald / Colors.green)
- **Stop / Danger Red**: `Color(0xFFEF4444)` / `Colors.red`
- **Warning / Amber Orange**: `Color(0xFFF59E0B)`

### 3. Typography (Google Fonts Inter)
- **Headings / App Titles**: Bold 800 / 700 with letter spacing `1.2` - `1.5`.
- **Card Titles**: Bold 700, 15px - 22px, `Color(0xFF1E293B)`.
- **Body & Subtitles**: Regular 400 / Medium 500, 12px - 14px, `Color(0xFF64748B)`.

### 4. Backgrounds & Cards
- **Brand Hero Gradient**: `LinearGradient(colors: [Color(0xFF1976D2), Color(0xFF0E5DB5)], begin: Alignment.topLeft, end: Alignment.bottomRight)`
- **Translucent Depth Circles**: `BoxShape.circle`, white color with `0.05` to `0.08` opacity.
- **Card Sizing & Radius**: `BorderRadius.circular(16)` to `BorderRadius.circular(28)` with soft blue border (`Color(0xFF1976D2)` 18%-25% opacity) and shadow (`Color(0xFF1976D2)` 6%-12% opacity, blur radius 10-28px).

### 5. Interactive Buttons & Controls
- **Primary Button**: Gradient `[Color(0xFF1976D2), Color(0xFF0E5DB5)]` with elevation shadow (`Color(0xFF1976D2)` 35% opacity, blur 12, offset 0 5), radius 14px-16px, height 52px.
- **Secondary Action Cards**: Fill `#F8FAFC`, border `Color(0xFF1976D2)` 22% opacity, radius 16px, icon container with `0.12` alpha fill.
- **Back Button**: Floating white elevation card, `BorderRadius.circular(12)`, icon `Icons.arrow_back_ios_new_rounded`.

### 6. Pop-Up Notifications & Snackbars Standard
All alerts, feedback, success toasts, and error snackbars across the tablet application must strictly follow this standard:
- **Position**: `SnackPosition.TOP`
- **Margin & Radius**: `margin: EdgeInsets.symmetric(horizontal: 20, vertical: 12)`, `borderRadius: BorderRadius.circular(12)`
- **Color Coding**:
  - **Success / Passed**: `Colors.green` / `Color(0xFF10B981)` with `Icons.check_circle_rounded` (white, 26px)
  - **Warning / Alert**: `Color(0xFFF59E0B)` with `Icons.warning_amber_rounded` (white, 26px)
  - **Error / Rejected**: `Colors.red` / `Color(0xFFEF4444)` with `Icons.cancel_rounded` (white, 26px)
  - **Info / General**: `Color(0xFF1976D2)` with `Icons.info_outline_rounded` (white, 26px)
- **Icon Animation Policy**: `shouldIconPulse: false` (icons must remain strictly solid and static; never blink or pulse).
- **Typography**:
  - **Title**: `fontSize: 15`, `fontWeight: FontWeight.bold`, `color: Colors.white`, `letterSpacing: 0.2`.
  - **Message**: `fontSize: 13.5`, `fontWeight: FontWeight.w500`, `color: Colors.white`.
- **Duration**: `const Duration(seconds: 3)`.
