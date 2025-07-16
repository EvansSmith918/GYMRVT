# GYMRVT
# GYMRVT

**GYMRVT** is a free, open-source mobile app that uses AI and your phone's camera to track weightlifting performance in real time. No sensors, no subscriptions — just your camera and smart computer vision.

## Features

- Automatic rep counting using real-time pose estimation
- Bar speed and tempo tracking based on joint movement
- Offline workout logging with exportable data
- Audio feedback to announce reps and performance
- 100% privacy-focused: all processing is local on the device
- will also connect to Phone Health Apps
  

## How It Works

GYMRVT uses TensorFlow Lite and the MoveNet model to detect body pose landmarks in real time. By analyzing joint angles and vertical movement, it estimates repetitions and bar speed for exercises like squats, bench press, curls, and more.

The app is built with Flutter for smooth cross-platform support and runs entirely offline.

## Tech Stack

- Flutter (Dart) for cross-platform mobile development
- TensorFlow Lite with MoveNet for pose detection
- SQLite for offline data logging
- Text-to-Speech for real-time audio feedback
- FL Chart for performance graphing

## Getting Started

1. Clone the repository:
   ```
   git clone https://github.com/EvansSmith918/GYMRVT
   cd GYMRVT
   ```

2. Install dependencies:
   ```
   flutter pub get
   ```

3. Run the app:
   ```
   flutter run
   ```

Make sure you have Flutter and Dart installed on your system.

## Project Structure

```
GYMRVT/
├── lib/
│   ├── main.dart
│   ├── pages/
│   ├── services/
│   ├── utils/
│   └── widgets/
├── assets/
│   └── tflite_model/
├── pubspec.yaml
```

## Contributing

Pull requests are welcome. If you'd like to contribute a feature, fix a bug, or suggest improvements, please open an issue or fork the project and submit a PR.

## License

This project is licensed under the MIT License.

## Disclaimer

GYMRVT is not a medical or diagnostic tool. It is intended for general fitness tracking only. Use at your own risk and consult a professional for medical or training advice.

