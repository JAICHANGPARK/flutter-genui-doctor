# Dr. GenUI: Generative UI Medical Consultation

**Dr. GenUI** is a cutting-edge medical consultation AI application built with **Flutter** and the **GenUI** package. It leverages Google's **Gemini AI** to provide a dynamic, interactive, and visually rich "Generative UI" experience for medical triage and consultation simulation.

Unlike traditional chatbots that only return text, Dr. GenUI dynamically renders specialized UI components (Calculated Items) within the conversation flow based on the AI's reasoning.

---

## ✨ Key Features

- **Generative UI (GenUI)**: Seamlessly integrates AI-driven logic with native Flutter widgets. The AI decides when and which UI components to show.
- **Dynamic Medical Triage**:
  - `pain_slider`: Interactive slider for pain level assessment.
  - `symptom_selector`: Multi-chip selector for detailed symptom reporting.
  - `diagnosis_card`: Beautifully rendered cards showing potential diagnoses, severity, and recommended departments.
  - `medication_list`: Custom list view for AI-recommended non-prescription medications.
- **Intelligent Conversation**: Powered by `gemini-1.5-flash` (or newer) via the `genui_google_generative_ai` package.
- **Modern UI/UX**: Features a clean, medical-themed design with a responsive, reverse-scroll chat interface.
- **Cross-Platform**: Ready for Android, iOS, Web, macOS, Windows, and Linux.

---

## 🛠 Technology Stack

- **Framework**: [Flutter](https://flutter.dev/)
- **AI Core**: [Google Generative AI (Gemini)](https://ai.google.dev/)
- **GenUI Engine**: [`genui`](https://pub.dev/packages/genui) package for Flutter.
- **Data Modeling**: `json_schema_builder` for structured UI communication.

---

## 🚀 Getting Started

### 1. Prerequisites
- Flutter SDK (latest stable version recommended)
- A Google AI (Gemini) API Key. Get one at [Google AI Studio](https://aistudio.google.com/).

### 2. Installation
Clone the repository and install dependencies:
```bash
git clone https://github.com/jaichangpark/flutter-genui-doctor.git
cd flutter-genui-doctor
flutter pub get
```

### 3. Configuration
Open `lib/main.dart` and locate the `_apiKey` constant in the `_ChatScreenState` class. Insert your API key:

```dart
// lib/main.dart

static const String _apiKey = 'YOUR_GEMINI_API_KEY_HERE';
```

### 4. Run the App
```bash
flutter run
```

---

## 📂 Project Structure

- `lib/main.dart`: The primary entry point. Contains the "Dr. GenUI" implementation, UI Catalog, and Chat logic.
- `lib/ai_waiter/`: Example implementation of an AI Waiter GenUI app.
- `lib/simple_chat/`: A simplified Chat UI example.
- `lib/configuration.dart`: Global configuration and logging setup.

---

## 🧪 How it Works: GenUI Catalog

The heart of the app is the `medicalCatalog`, which defines the "vocabulary" of UI components the AI can use:

```dart
final medicalCatalog = Catalog([
  painSlider,       // Input: Pain Level
  symptomSelector, // Input: Multiple Symptoms
  diagnosisCard,    // Output: Medical Diagnosis
  medicationList,   // Output: Recommended Medication
]);
```

The AI is instructed via a **System Instruction** to use these specific tools at appropriate stages of the medical consultation flow.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## ⚠️ Disclaimer

*This application is for demonstration purposes only. It is not a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition.*
