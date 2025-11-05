💬 Flikchat: Real-Time, Privacy-First Emotion AI Chat
Flikchat is a fully-featured Flutter chat app that redefines real-time communication by integrating on-device Facial Emotion Recognition (FER). It shares your current mood as a live status with your chat partner—securely, privately, and instantly.
This project is a complete demonstration of a production-ready, privacy-first AI feature—from training a Keras model to deploying a high-performance TensorFlow Lite model, all backed by a real-time cloud infrastructure.

🚀 Demo
Record a GIF of your app working on two phones (or one phone and the Firebase console) and paste it here:
App Demo GIF
A visual demo showing the chat, emotion capsule updates, and Firebase console changes is essential. Use tools like GIPHY Capture or Ezgif to record.


✨ Core Features
- 📸 Real-Time Emotion Analysis
Captures a snapshot every 5 seconds using the front-facing camera.
- ⚡ 100% On-Device AI
Inference is performed locally using a custom TensorFlow Lite model—zero latency, no server costs.
- 🔐 Privacy-First Architecture
Images are analyzed in-memory and discarded immediately. Only the emotion label (e.g., "Happy") is transmitted.
- 💬 Live Emotion Capsule
Displays your partner’s emotion in real-time using a StreamBuilder connected to Firestore.
- 🧭 Full User Control
Users can opt-in/out via a settings toggle. Preferences are stored locally.
- 🗨️ Complete Chat System
Includes user authentication and one-on-one messaging.

🏗️ Architecture & Data Flow
graph TD
    A[Settings Toggle] --> B[SharedPreferences: true/false]
    B --> C[ChatPage initState]
    C --> D[Load .tflite model]
    D --> E[Initialize front camera]
    E --> F[Timer.periodic (5s)]
    F --> G[Capture snapshot]
    G --> H[Preprocess image (48x48, grayscale, normalize)]
    H --> I[TFLite inference → emotion label]
    I --> J[Delete image from storage]
    J --> K[Write label to Firestore]
    K --> L[StreamBuilder on partner’s phone]
    L --> M[Update UI capsule]



🛠️ Tech Stack
🔧 Core
- Flutter (Frontend)
- Firebase Authentication & Cloud Firestore (Backend)
🤖 AI/ML
- Python, TensorFlow, Keras (Training)
- TensorFlow Lite via tflite_flutter (Deployment)
- image package for preprocessing
📦 Key Flutter Packages


🔌 Setup & Run
1. Clone the Repository
git clone https://github.com/rishikeshjoshy/flickchat.git
cd flickchat.git


2. Set Up Firebase
- Create a Firebase project.
- Add a Flutter app.
- Run:
flutterfire configure


- Enable Email/Password Authentication and Cloud Firestore.
3. Install Dependencies
flutter pub get


4. Run the App
flutter run



🧠 Future Improvements
- 🔋 Battery Optimization
Replace the 5-second timer with event-driven triggers:
- When the keyboard opens
- When app is foregrounded and a new message arrives
- 🧠 Model v2
Retrain using a larger, more diverse dataset (e.g., AffectNet) for better accuracy and fairness.
- 🎯 Smarter State Management
Avoid sending "Neutral" updates. Only transmit strong emotions sustained for >2 seconds.

📬 Contributing
Pull requests are welcome! For major changes, please open an issue first to discuss what you’d like to change.

📄 License
MIT
