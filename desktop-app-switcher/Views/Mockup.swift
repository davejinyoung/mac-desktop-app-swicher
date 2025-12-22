//import SwiftUI
//import ScreenCaptureKit
//import AppKit
//
//struct WindowPreviewDemo: View {
//   @State private var windows: [WindowInfo] = []
//   @State private var errorMessage: String?
//   
//   var body: some View {
//       VStack(spacing: 20) {
//           if !windows.isEmpty {
//               ScrollView {
//                   LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 16) {
//                       ForEach(windows) { windowInfo in
//                           VStack {
//                               if let preview = windowInfo.preview {
//                                   Image(nsImage: preview)
//                                       .resizable()
//                                       .aspectRatio(contentMode: .fit)
//                                       .frame(maxHeight: 150)
//                                       .border(Color.gray)
//                               } else {
//                                   Rectangle()
//                                       .fill(Color.gray.opacity(0.3))
//                                       .frame(height: 150)
//                                       .overlay(Text("No preview"))
//                               }
//                               
//                               Text(windowInfo.title)
//                                   .font(.caption)
//                                   .lineLimit(2)
//                                   .multilineTextAlignment(.center)
//                               
//                               Text(windowInfo.appName)
//                                   .font(.caption2)
//                                   .foregroundColor(.secondary)
//                           }
//                           .padding(8)
//                           .background(Color.gray.opacity(0.1))
//                           .cornerRadius(8)
//                       }
//                   }
//                   .padding()
//               }
//           } else if let errorMessage {
//               Text(errorMessage)
//                   .foregroundColor(.red)
//                   .multilineTextAlignment(.center)
//           } else {
//               Text("No windows captured yet")
//                   .foregroundColor(.secondary)
//           }
//           
//           Button("Grab All Windows") {
//               Task {
//                   do {
//                       windows = try await captureAllWindows()
//                       errorMessage = nil
//                   } catch {
//                       errorMessage = "Error: \(error.localizedDescription)"
//                   }
//               }
//           }
//           .buttonStyle(.borderedProminent)
//       }
//       .padding()
//       .frame(minWidth: 800, minHeight: 600)
//   }
//}
//
//struct WindowInfo: Identifiable {
//   let id = UUID()
//   let title: String
//   let appName: String
//   let preview: NSImage?
//}
//
//func captureAllWindows() async throws -> [WindowInfo] {
//   // Get all shareable content
//   let content = try await SCShareableContent.excludingDesktopWindows(
//       false,
//       onScreenWindowsOnly: true
//   )
//   
//   var windowInfos: [WindowInfo] = []
//   
//   // Iterate through all windows
//   for window in content.windows {
//       // Skip windows without titles or very small windows
//       guard let title = window.title,
//             !title.isEmpty,
//             window.frame.width > 50,
//             window.frame.height > 50 else {
//           continue
//       }
//       
//       // Get app name
//       let appName = window.owningApplication?.applicationName ?? "Unknown"
//       
//       // Try to capture the window
//       let preview = try? await captureWindow(window)
//       
//       windowInfos.append(WindowInfo(
//           title: title,
//           appName: appName,
//           preview: preview
//       ))
//   }
//   
//   return windowInfos
//}
//
//func captureWindow(_ window: SCWindow) async throws -> NSImage? {
//   // Create a content filter for this window
//   let filter = SCContentFilter(desktopIndependentWindow: window)
//   
//   // Configure the capture
//   let config = SCStreamConfiguration()
//   config.scalesToFit = true
//   
//   // Capture a single frame
//   let image = try await SCScreenshotManager.captureImage(
//       contentFilter: filter,
//       configuration: config
//   )
//   
//   // Convert CGImage to NSImage
//   return NSImage(cgImage: image, size: NSSize(width: window.frame.width, height: window.frame.height))
//}
