import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether TTS score announcements are enabled.
final ttsEnabledProvider = StateProvider<bool>((ref) => false);

/// Provides the TTS service singleton.
final ttsServiceProvider = Provider<TtsService>((ref) => TtsService(ref));

/// Text-to-speech service for announcing dart scores.
class TtsService {
  final Ref _ref;
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  TtsService(this._ref) {
    _loadSetting();
  }

  Future<void> _init() async {
    if (_initialized) return;
    _initialized = true;
    await _tts.setLanguage('en-US');
    await _tts.setVolume(1.0);
  }

  Future<void> _loadSetting() async {
    final prefs = await SharedPreferences.getInstance();
    _ref.read(ttsEnabledProvider.notifier).state =
        prefs.getBool('ttsEnabled') ?? false;
  }

  /// Toggle TTS on/off and persist the setting.
  Future<void> toggle() async {
    final current = _ref.read(ttsEnabledProvider);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ttsEnabled', !current);
    _ref.read(ttsEnabledProvider.notifier).state = !current;
  }

  /// Speak the thrown score number with enthusiasm based on score value.
  Future<void> speakScore(int score) async {
    if (!_ref.read(ttsEnabledProvider)) return;
    await _init();

    // Higher scores → faster speech and higher pitch
    // Score range: 0-180
    // Rate: 0.6 (low scores) → 1.0 (high scores)
    // Pitch: 1.0 (low scores) → 1.5 (180)
    final ratio = (score / 180).clamp(0.0, 1.0);
    final rate = 0.6 + (ratio * 0.4);
    final pitch = 1.0 + (ratio * 0.5);

    await _tts.setSpeechRate(rate);
    await _tts.setPitch(pitch);

    if (score == 180) {
      await _tts.speak('One hundred and eighty!');
    } else {
      await _tts.speak('$score');
    }
  }

  /// Announce that a player requires a checkout score.
  Future<void> speakCheckout(String playerName, int remaining) async {
    if (!_ref.read(ttsEnabledProvider)) return;
    await _init();
    await _tts.setSpeechRate(0.65);
    await _tts.setPitch(1.0);
    await _tts.speak('$playerName requires $remaining');
  }
}
