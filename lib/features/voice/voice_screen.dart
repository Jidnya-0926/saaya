import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'voice_service.dart';

class VoiceScreen extends StatefulWidget {
  final bool isTestMode;
  const VoiceScreen({super.key, this.isTestMode = false});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  bool _isListening = false;
  String _recognizedWords = '';
  String _currentKeyword = '';
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    _currentKeyword = VoiceService.getKeyword();
  }

  void _startListening() async {
    setState(() {
      _recognizedWords = '';
      _testSuccess = false;
    });

    await VoiceService.startListening(
      onListeningStarted: () => setState(() => _isListening = true),
      onListeningStopped: () => setState(() => _isListening = false),
      onResult: (recognized) {
        setState(() {
          _recognizedWords = recognized;
          _isListening = false;
        });

        if (widget.isTestMode) {
          if (VoiceService.isKeywordMatch(recognized)) {
            setState(() => _testSuccess = true);
          }
        }
      },
    );
  }

  void _saveKeyword() async {
    if (_recognizedWords.trim().isEmpty) return;
    await VoiceService.saveKeyword(_recognizedWords);
    setState(() {
      _currentKeyword = VoiceService.getKeyword();
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Voice Keyword saved as: '$_currentKeyword'")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isTestMode ? "Test Voice Activation" : "Set Your Voice Keyword"),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              Icon(
                _isListening ? Icons.mic_rounded : Icons.lock_person_rounded,
                size: 80,
                color: _isListening ? AppTheme.emergencyRed : AppTheme.safeGreen,
              ),
              const SizedBox(height: 20),
              Text(
                _isListening
                    ? "Listening for your secret phrase..."
                    : _testSuccess
                        ? "✓ Voice Keyword Recognized!"
                        : "Ready to listen",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                widget.isTestMode
                    ? "Speak your configured phrase to test recognition. SOS will not be triggered."
                    : "Tap the button below and speak your secret emergency phrase.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 30),
              // Current Saved Keyword
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Configured Keyword:", style: TextStyle(fontWeight: FontWeight.bold)),
                      Chip(
                        backgroundColor: AppTheme.safeGreen.withValues(alpha: 0.15),
                        label: Text(
                          _currentKeyword.toUpperCase(),
                          style: const TextStyle(color: AppTheme.safeGreen, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Heard Text Display
              if (_recognizedWords.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Heard Phrase:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(
                        '"$_recognizedWords"',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              // Buttons
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isListening ? AppTheme.warningOrange : AppTheme.emergencyRed,
                  ),
                  icon: Icon(_isListening ? Icons.stop : Icons.mic),
                  label: Text(_isListening ? "Stop Listening" : "Start Listening"),
                  onPressed: () {
                    if (_isListening) {
                      VoiceService.stopListening();
                    } else {
                      _startListening();
                    }
                  },
                ),
              ),
              if (!widget.isTestMode && _recognizedWords.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text("Use This Keyword"),
                    onPressed: _saveKeyword,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
