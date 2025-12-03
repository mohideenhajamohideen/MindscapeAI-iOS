# 🧠 Mindscape: AI Memory Palace

> **Transform your documents into immersive 3D worlds.**

[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%2017+-lightgrey.svg)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

**Mindscape** is a revolutionary iOS application that leverages the ancient "Method of Loci" (Memory Palace) technique combined with modern Generative AI. Simply upload a PDF, and Mindscape automatically constructs a 3D spatial environment where key concepts are represented as interactive objects.

---

## ✨ Features

*   **📄 PDF to 3D World**: Instantly convert boring text documents into vibrant, procedurally generated 3D palaces.
*   **🏰 Spatial Learning**: Walk through your notes. Concepts are placed spatially to leverage your brain's natural navigation memory.
*   **🤖 AI-Powered Analysis**: Deep understanding of your content. The AI extracts key facts, relationships, and generates mnemonics.
*   **💬 Contextual Chat**: Talk to your palace! Ask questions about the uploaded document and get instant, context-aware answers.
*   **🎧 Immersive Audio**: Listen to AI-narrated scripts and key takeaways for every concept as you explore.
*   **🎨 Dynamic Themes**: Beautiful, procedurally generated environments with dynamic lighting and textures.

---

## 🛠️ Tech Stack

*   **Language**: Swift 5.9
*   **UI Framework**: SwiftUI
*   **3D Engine**: SceneKit
*   **Networking**: URLSession (Multipart/form-data uploads)
*   **Architecture**: MVVM (Model-View-ViewModel)
*   **Backend Integration**: Connects to a custom Python/FastAPI backend for AI processing.

---

## 🚀 Getting Started

### Prerequisites

*   Xcode 15.0 or later
*   iOS 17.0+ Device or Simulator
*   A running instance of the Mindscape Backend (or access to the production API)

### Installation

1.  **Clone the repository**
    ```bash
    git clone https://github.com/mohideenhajamohideen/MindscapeAI-iOS.git
    cd MindscapeAI-iOS
    ```

2.  **Open the Project**
    Open `MindscapeAI.xcworkspace` in Xcode.

3.  **Configuration**
    *   Ensure `Info.plist` is correctly set up for App Transport Security if testing with a local backend.
    *   Verify the `APIService.swift` `baseURL` points to your backend instance.

4.  **Build and Run**
    Select your target device and hit `Cmd + R`.

---

## 📱 Usage

1.  **Login/Sign Up**: Access your secure account.
2.  **Upload**: Tap the "+" button to select a PDF document from your files.
3.  **Wait for Magic**: The app uploads the file and constructs the 3D scene (usually takes 10-20 seconds).
4.  **Explore**:
    *   **Navigate**: Swipe to look around, pinch to zoom/move.
    *   **Interact**: Tap on floating spheres to view concept details.
    *   **Chat**: Tap the chat icon to ask questions about the content.

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the Branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  Built with ❤️ by Mohideen
</p>
