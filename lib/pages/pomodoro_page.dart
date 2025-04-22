import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';

class PomodoroPage extends StatefulWidget {
  const PomodoroPage({super.key});

  @override
  PomodoroPageState createState() => PomodoroPageState();
}

class PomodoroPageState extends State<PomodoroPage> {
  // Timer related variables
  Timer? _timer;
  int _secondsRemaining = 25 * 60; // Default 25 minutes
  int _totalSeconds = 25 * 60; // To calculate progress
  bool _isRunning = false;
  bool _isBreak = false;

  // Settings
  int _workDuration = 25; // minutes
  int _shortBreakDuration = 5; // minutes
  int _longBreakDuration = 15; // minutes
  int _sessionsBeforeLongBreak = 4;
  int _completedSessions = 0;

  // Controllers for text fields
  final TextEditingController _workController = TextEditingController(text: '25');
  final TextEditingController _shortBreakController = TextEditingController(text: '5');
  final TextEditingController _longBreakController = TextEditingController(text: '15');
  final TextEditingController _sessionsController = TextEditingController(text: '4');

  @override
  void initState() {
    super.initState();
    _resetTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _workController.dispose();
    _shortBreakController.dispose();
    _longBreakController.dispose();
    _sessionsController.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (_timer != null) {
      _timer!.cancel();
    }

    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timer?.cancel();
          _isRunning = false;
          _handleTimerComplete();
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = _isBreak
          ? (_completedSessions % _sessionsBeforeLongBreak == 0 && _completedSessions > 0
          ? _longBreakDuration * 60
          : _shortBreakDuration * 60)
          : _workDuration * 60;
      _totalSeconds = _secondsRemaining;
      _isRunning = false;
    });
  }

  void _skipToNext() {
    setState(() {
      if (_isBreak) {
        // If currently in break, switch to work
        _isBreak = false;
        _secondsRemaining = _workDuration * 60;
      } else {
        // If currently in work, switch to break and increment completed sessions
        _completedSessions++;
        // Reset sessions counter after completing all sessions
        if (_completedSessions >= _sessionsBeforeLongBreak) {
          _completedSessions = 0;
        }
        _isBreak = true;
        _secondsRemaining = _completedSessions % _sessionsBeforeLongBreak == 0
            ? _longBreakDuration * 60
            : _shortBreakDuration * 60;
      }
      _totalSeconds = _secondsRemaining;
      _isRunning = false;
    });
    _timer?.cancel();
  }

  void _handleTimerComplete() {
    HapticFeedback.heavyImpact(); // Vibration feedback

    // Show popup dialog that requires user interaction
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap button to close dialog
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            _isBreak ? 'Break Time Finished!' : 'Work Session Completed!',
            style: TextStyle(
              color: _isBreak ? Colors.green : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
              _isBreak
                  ? 'Time to get back to work!'
                  : _completedSessions % _sessionsBeforeLongBreak == (_sessionsBeforeLongBreak - 1)
                  ? 'Great job! Take a long break now.'
                  : 'Well done! Take a short break.'
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Continue'),
              onPressed: () {
                Navigator.of(context).pop();
                _skipToNext();
                // Auto-start the next session
                _startTimer();
              },
            ),
          ],
        );
      },
    );
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pomodoro Settings'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _workController,
                decoration: const InputDecoration(labelText: 'Work duration (minutes)'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              TextField(
                controller: _shortBreakController,
                decoration: const InputDecoration(labelText: 'Short break duration (minutes)'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              TextField(
                controller: _longBreakController,
                decoration: const InputDecoration(labelText: 'Long break duration (minutes)'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              TextField(
                controller: _sessionsController,
                decoration: const InputDecoration(labelText: 'Sessions before long break'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Update settings with new values
              setState(() {
                _workDuration = int.parse(_workController.text);
                _shortBreakDuration = int.parse(_shortBreakController.text);
                _longBreakDuration = int.parse(_longBreakController.text);
                _sessionsBeforeLongBreak = int.parse(_sessionsController.text);
              });
              _resetTimer();
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate progress (from 0.0 to 1.0)
    double progress = _totalSeconds > 0 ? _secondsRemaining / _totalSeconds : 0;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Status text
            Text(
              _isBreak
                  ? (_completedSessions % _sessionsBeforeLongBreak == 0
                  ? 'Long Break'
                  : 'Short Break')
                  : 'Focus Time',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Session counter
            Text(
              'Session ${_completedSessions + 1} ' +
                  (_sessionsBeforeLongBreak > 0
                      ? '/ $_sessionsBeforeLongBreak before long break'
                      : ''),
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),

            // Timer circle with progress indicator
            Stack(
              alignment: Alignment.center,
              children: [
                // Progress indicator
                SizedBox(
                  width: screenWidth * 0.7,
                  height: screenWidth * 0.7,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey.shade300,
                    color: _isBreak ? Colors.green : Colors.black,
                  ),
                ),
                // Timer container
                Container(
                  width: screenWidth * 0.62,
                  height: screenWidth * 0.62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: _isBreak ? Colors.green.shade100 : Colors.grey.shade200,
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _formatTime(_secondsRemaining),
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: _isBreak ? Colors.green : Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.restart_alt, size: 35),
                  onPressed: _resetTimer,
                ),
                const SizedBox(width: 20),
                IconButton(
                  icon: Icon(
                    _isRunning ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    size: 60,
                    color: Colors.black,
                  ),
                  onPressed: _isRunning ? _pauseTimer : _startTimer,
                ),
                const SizedBox(width: 20),
                IconButton(
                  icon: const Icon(Icons.skip_next, size: 35),
                  onPressed: _skipToNext,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Settings button
            TextButton.icon(
              icon: const Icon(Icons.settings),
              label: const Text('Settings'),
              onPressed: _showSettingsDialog,
            ),
          ],
        ),
      ),
    );
  }
}