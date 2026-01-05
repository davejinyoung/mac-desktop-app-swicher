# MacOS Desktop App Switcher

This is a macOS application that provides a fast and visual application switcher, triggered by a global hotkey. 
It displays the icons of all running applications on your current desktop, allowing you to quickly switch between them without being distracted by apps on other desktops.

### The Problem with the Native App Switcher
Natively, the macOS app switcher (Command+Tab) shows you all running applications across all of your desktops (Spaces). 
This can be overwhelming and counterproductive if you use multiple desktops to organize your work.

### A More Focused Solution
This application is designed to solve that problem. 
It limits the app switcher to only the applications that are running on your current desktop. 
This helps you stay focused on your current context and switch between relevant apps more efficiently.

### Features
- Displays all running apps on the current desktop as a floating panel
- Option to display application window thumbnails
- Replicates native app cycling behaviour
- Ability to customize the shortcut binding to your preferred modifier+key combo
- Ability to update the size of the panel
- Ability to quit a running app by clicking a customizable key on the currently selected app on the panel
- Ability to close a window instance of a running app by clicking a customizable key on the currently selected app on the panel
- Ability to open a new window of a running app by clicking a customizable key on the currently selected app on the panel
- Can choose to display only the applications on the current desktop/space or all applications
- Ability to determine whether holding the app switcher shortcut continuously cycles through apps or stops at the last/first app, depending on user settings.

### Usage
1. Clone the repository and open the project on Xcode.
2. Navigate to the "Product" tab on the top bar and click "Archive".
3. On the Archives modal, click "Distribute App".
4. On the method of distribution modal, click "Custom" and click "Next".
5. Choose the "Copy App" option and click "Next"
6. Export the app.
7. Navigate to the location where the app was exported and run the app.
8. Allow prompted permissions requests in System Settings.
9. Use Option+Tab to navigate between apps!

<br>
<div align="center">
  <img width="676" height="232" alt="Screenshot 2025-12-23 at 11 50 38 AM" src="https://github.com/user-attachments/assets/bcdc218c-5bb0-485c-a57b-d2f47a99848e" />
  <br>
  <em>Panel with app icon view</em>
</div>

<br>
<div align="center">
  <img width="1888" height="394" alt="Screenshot 2025-12-23 at 11 51 26 AM" src="https://github.com/user-attachments/assets/403dbdbe-43bc-4016-bfa0-38a68000965c" />
  <br>
  <em>Panel with window thumbnail view</em>
</div>

