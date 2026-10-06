import 'package:flutter/material.dart';
import 'package:hr_management/core/services/auth_storage.dart';
import 'package:hr_management/core/widgets/hr_drawer.dart';
import '../../data/services/draw_guess_api_service.dart';

class DrawGuessLobbyPage extends StatefulWidget {
  const DrawGuessLobbyPage({super.key});

  @override
  State<DrawGuessLobbyPage> createState() => _DrawGuessLobbyPageState();
}

class _DrawGuessLobbyPageState extends State<DrawGuessLobbyPage> {
  final TextEditingController _roomNameController = TextEditingController();
  final TextEditingController _joinCodeController = TextEditingController();

  int _maxRounds = 3;
  int _drawTimeSeconds = 80;
  String _selectedCategory = 'GENERAL';
  final bool _customWordsOnly = false;

  bool _isCreating = false;
  bool _isJoining = false;
  List<String> _categories = ['GENERAL', 'TECH', 'HR_OFFICE', 'ANIMALS', 'NATURE', 'FOOD', 'OBJECTS'];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await DrawGuessApiService.getCategories();
      if (mounted) setState(() => _categories = cats);
    } catch (_) {}
  }

  Future<void> _createRoom() async {
    setState(() => _isCreating = true);
    try {
      final room = await DrawGuessApiService.createRoom(
        roomName: _roomNameController.text.trim(),
        maxRounds: _maxRounds,
        drawTimeSeconds: _drawTimeSeconds,
        category: _selectedCategory,
        customWordsOnly: _customWordsOnly,
      );

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/draw-and-guess/room',
          arguments: {'roomCode': room.roomCode, 'isHost': true},
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create room: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _joinRoom() async {
    final code = _joinCodeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a 6-character room code.')),
      );
      return;
    }

    setState(() => _isJoining = true);
    try {
      final room = await DrawGuessApiService.joinRoom(code);
      if (mounted) {
        final currentEmpId = AuthStorage.employeeId;
        final isHost = currentEmpId != null && currentEmpId == room.hostEmployeeId;
        Navigator.pushReplacementNamed(
          context,
          '/draw-and-guess/room',
          arguments: {'roomCode': room.roomCode, 'isHost': isHost},
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join room: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  @override
  void dispose() {
    _roomNameController.dispose();
    _joinCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      drawer: const HrDrawer(),
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.brush_rounded, color: Color(0xFF6366F1), size: 24),
              SizedBox(width: 10),
              Text(
                'DRAW & GUESS LOBBY',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Banner Hero Card
                _buildHeroBanner(context),
                const SizedBox(height: 24),

                // 2 Column Layout for Create & Join
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 700) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildCreateRoomCard(context)),
                          const SizedBox(width: 24),
                          Expanded(child: _buildJoinRoomCard(context)),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        _buildCreateRoomCard(context),
                        const SizedBox(height: 24),
                        _buildJoinRoomCard(context),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF0D9488)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'MULTIPLAYER SOCIAL GAME',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Draw, Guess & Compete in Real-Time!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Create an internal game room or join with a 6-character room code to play with teammates.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const Icon(Icons.draw_rounded, color: Colors.white, size: 56),
        ],
      ),
    );
  }

  Widget _buildCreateRoomCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF6366F1), size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'CREATE GAME ROOM',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.8),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Room Name
          TextField(
            controller: _roomNameController,
            decoration: InputDecoration(
              labelText: 'Room Name (Optional)',
              hintText: 'e.g. Frontend Team Scribble',
              filled: true,
              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),

          // Category Dropdown
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            decoration: InputDecoration(
              labelText: 'Word Category',
              filled: true,
              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: _categories.map((c) {
              return DropdownMenuItem(value: c, child: Text(c));
            }).toList(),
            onChanged: (v) {
              if (v != null) setState(() => _selectedCategory = v);
            },
          ),
          const SizedBox(height: 16),

          // Max Rounds
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Rounds:', style: TextStyle(fontWeight: FontWeight.w600)),
              Text('$_maxRounds rounds', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF6366F1))),
            ],
          ),
          Slider(
            value: _maxRounds.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            activeColor: const Color(0xFF6366F1),
            onChanged: (v) => setState(() => _maxRounds = v.toInt()),
          ),
          const SizedBox(height: 8),

          // Draw Time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Draw Time:', style: TextStyle(fontWeight: FontWeight.w600)),
              Text('${_drawTimeSeconds}s per turn', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF6366F1))),
            ],
          ),
          Slider(
            value: _drawTimeSeconds.toDouble(),
            min: 45,
            max: 120,
            divisions: 5,
            activeColor: const Color(0xFF6366F1),
            onChanged: (v) => setState(() => _drawTimeSeconds = v.toInt()),
          ),
          const SizedBox(height: 16),

          // Create Action Button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _isCreating ? null : _createRoom,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isCreating
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Create & Host Room', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinRoomCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.login_rounded, color: Color(0xFF0D9488), size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'JOIN WITH CODE',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.8),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            'Enter the 6-character room code shared by your teammate host.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),

          // Code Input
          TextField(
            controller: _joinCodeController,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 6,
            ),
            maxLength: 10,
            decoration: InputDecoration(
              counterText: '',
              hintText: 'DGXXXX',
              hintStyle: TextStyle(
                color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                letterSpacing: 4,
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 24),

          // Join Action Button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _isJoining ? null : _joinRoom,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isJoining
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Enter Game Room', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
