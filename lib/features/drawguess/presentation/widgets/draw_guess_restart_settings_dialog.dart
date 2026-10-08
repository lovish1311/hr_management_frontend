import 'package:flutter/material.dart';
import '../../data/services/draw_guess_api_service.dart';

class DrawGuessRestartSettingsDialog extends StatefulWidget {
  final String roomCode;
  final int initialRounds;
  final int initialDrawTime;
  final String initialCategory;
  final VoidCallback onGameRestarting;

  const DrawGuessRestartSettingsDialog({
    super.key,
    required this.roomCode,
    this.initialRounds = 3,
    this.initialDrawTime = 80,
    this.initialCategory = 'GENERAL',
    required this.onGameRestarting,
  });

  @override
  State<DrawGuessRestartSettingsDialog> createState() => _DrawGuessRestartSettingsDialogState();
}

class _DrawGuessRestartSettingsDialogState extends State<DrawGuessRestartSettingsDialog> {
  late int _selectedRounds;
  late int _selectedDrawTime;
  late String _selectedCategory;
  bool _isLoading = false;
  String? _errorMessage;

  static const List<int> _roundOptions = [2, 3, 5, 8];
  static const List<int> _drawTimeOptions = [30, 60, 80, 100, 120];
  static const List<String> _categories = [
    'GENERAL',
    'TECH',
    'HR_OFFICE',
    'ANIMALS',
    'FOOD',
    'OBJECTS',
  ];

  @override
  void initState() {
    super.initState();
    _selectedRounds = widget.initialRounds;
    _selectedDrawTime = widget.initialDrawTime;
    _selectedCategory = widget.initialCategory;
  }

  Future<void> _handleRestart() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await DrawGuessApiService.restartGame(
        widget.roomCode,
        maxRounds: _selectedRounds,
        drawTimeSeconds: _selectedDrawTime,
        category: _selectedCategory,
      );

      if (mounted) {
        widget.onGameRestarting();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.settings_suggest_rounded, color: Color(0xFF6366F1), size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Restart Game Settings',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Keep same room & players, start fresh',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Rounds Selection
            const Text(
              'NUMBER OF ROUNDS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _roundOptions.map((rounds) {
                final isSelected = _selectedRounds == rounds;
                return ChoiceChip(
                  label: Text('$rounds Rounds'),
                  selected: isSelected,
                  selectedColor: const Color(0xFF6366F1),
                  backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 12,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedRounds = rounds);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Draw Time Selection
            const Text(
              'DRAW TIME PER TURN',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _drawTimeOptions.map((seconds) {
                final isSelected = _selectedDrawTime == seconds;
                return ChoiceChip(
                  label: Text('${seconds}s'),
                  selected: isSelected,
                  selectedColor: const Color(0xFF6366F1),
                  backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 12,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedDrawTime = seconds);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Category Selection
            const Text(
              'WORD CATEGORY',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat.replaceAll('_', ' ')),
                  selected: isSelected,
                  selectedColor: const Color(0xFF10B981),
                  backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 12,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedCategory = cat);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRestart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Start New Game', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
