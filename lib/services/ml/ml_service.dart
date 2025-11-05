// lib/services/ml/ml_service.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img; // Import the image package


class MlService {
  Interpreter? _interpreter;

  // --- NEW ---
  // Define the emotion labels in the order your model was trained
  // IMPORTANT: You MUST update this list to match your model's output
  final List<String> _labels = [
    'Angry',
    'Disgust',
    'Fear',
    'Happy',
    'Sad',
    'Surprise',
    'Neutral'
  ];

  bool get isModelLoaded => _interpreter != null;

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/ml/model.tflite');
      print('TFLite model loaded successfully.');
    } catch (e) {
      print('Failed to load TFLite model: $e');
    }
  }

  // --- NEW ---
  // This function takes the photo, processes it, and runs inference.
  Future<String?> runInference(String imagePath) async {
    if (_interpreter == null) {
      print('Interpreter not loaded');
      return null;
    }

    try {
      // 1. Load and Decode Image
      final imageBytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null) {
        print('Failed to decode image');
        return null;
      }

      // 2. Resize to 48x48
      // Models are sensitive to the interpolation method.
      // You may need to experiment with:
      // - img.Interpolation.linear
      // - img.Interpolation.cubic
      // - img.Interpolation.average
      final resizedImage = img.copyResize(
        image,
        width: 48,
        height: 48,
        interpolation: img.Interpolation.average,
      );

      // 3. Convert to Grayscale
      final grayscaleImage = img.grayscale(resizedImage);

      // 4. Convert to [1, 48, 48, 1] Float32List
      final inputBuffer = _imageToFloat32List(grayscaleImage);

      // 5. Define model output shape
      // IMPORTANT: This assumes your model outputs a list of 7 probabilities.
      // e.g., [0.1, 0.05, 0.05, 0.7, 0.05, 0.0, 0.05]
      // Update [1, 7] to match your model's exact output shape.
      final outputBuffer = List.filled(1 * _labels.length, 0.0).reshape([1, _labels.length]);

      // 6. Run Inference
      _interpreter!.run(inputBuffer, outputBuffer);

      // 7. Get the winning label
      final resultLabel = _getTopLabel(outputBuffer[0]);
      return resultLabel;

    } catch (e) {
      print('Error running inference: $e');
      return null;
    }
  }

  // --- NEW ---
  // Helper function to convert the 48x48 grayscale image to a Float32List
  List _imageToFloat32List(img.Image image) {
    // 1 (batch) * 48 (height) * 48 (width) * 1 (channel)
    final inputList = Float32List(1 * 48 * 48 * 1);
    int bufferIndex = 0;

    for (int y = 0; y < 48; y++) {
      for (int x = 0; x < 48; x++) {
        // Gets the pixel and extracts the grayscale value (R, G, and B are same)
        final pixel = image.getPixel(x, y);
        final grayscale = pixel.r.toDouble(); // Or pixel.g, pixel.b

        // Normalize the pixel value from [0, 255] to [0, 1]
        // **IMPORTANT**: If your model was trained on [-1, 1],
        // use: (grayscale - 127.5) / 127.5
        inputList[bufferIndex++] = grayscale / 255.0;
      }
    }
    // Reshape to [1, 48, 48, 1] as required by the model
    return inputList.reshape([1, 48, 48, 1]);
  }

  // --- NEW ---
  // Helper function to find the label with the highest probability
  String _getTopLabel(List<double> probabilities) {
    double maxProb = 0.0;
    String topLabel = 'Unknown';

    for (int i = 0; i < probabilities.length; i++) {
      if (probabilities[i] > maxProb) {
        maxProb = probabilities[i];
        topLabel = _labels[i];
      }
    }
    return topLabel;
  }

  void dispose() {
    _interpreter?.close();
  }
}