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
    await _tts.setSpeechRate(0.45);
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

  /// Speak the thrown score number.
  Future<void> speakScore(int score) async {
    if (!_ref.read(ttsEnabledProvider)) return;
    await _init();
    await _tts.speak('$score');
  }

  /// Announce that a player requires a checkout score.
  Future<void> speakCheckout(String playerName, int remaining) async {
    if (!_ref.read(ttsEnabledProvider)) return;
    await _init();
    await _tts.speak('$playerName requires $remaining');
  }
}
