import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hr_management/core/services/auth_storage.dart';
import '../../data/models/tambola_models.dart';
import '../../data/services/tambola_api_service.dart';
import 'tambola_game_room_page.dart';

class TambolaLobbyPage extends StatefulWidget {
  const TambolaLobbyPage({super.key});

  @override
  State<TambolaLobbyPage> createState() => _TambolaLobbyPageState();
}

class _TambolaLobbyPageState extends State<TambolaLobbyPage> {
  final TextEditingController _roomCodeController = TextEditingController();
  List<TambolaGame> _games = [];
  bool _isLoading = true;
  bool _isActionLoading = false;
  String? _errorMessage;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchGames();
    _refreshTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (mounted) _fetchGames(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _roomCodeController.dispose();
    super.dispose();
  }

  Future<void> _fetchGames({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final list = await TambolaApiService.getActiveGames();
      if (mounted) {
        setState(() {
          _games = list;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleJoinGame([String? code]) async {
    final roomCode = (code ?? _roomCodeController.text).trim().toUpperCase();
    if (roomCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a 6-character room code')),
      );
      return;
    }

    setState(() => _isActionLoading = true);
    try {
      await TambolaApiService.joinGame(roomCode);
      if (mounted) {
        setState(() => _isActionLoading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TambolaGameRoomPage(roomCode: roomCode),
          ),
        ).then((_) => _fetchGames(silent: true));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isActionLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text(e.toString().replaceAll('Exception:', '').trim()),
          ),
        );
      }
    }
  }

  Future<void> _showCreateGameDialog() async {
    final titleController = TextEditingController(text: 'Company Tambola');
    int? autoInterval;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Row(
                children: [
                  Text('🎟️', style: TextStyle(fontSize: 24)),
                  SizedBox(width: 10),
                  Text('Host New Tambola Game', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Game Title', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'e.g. Friday Fun Tambola',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Number Draw Mode', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int?>(
                      dropdownColor: const Color(0xFF0F172A),
                      initialValue: autoInterval,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Manual Draw (Host calls each number)')),
                        DropdownMenuItem(value: 5, child: Text('Automatic - Every 5 Seconds')),
                        DropdownMenuItem(value: 8, child: Text('Automatic - Every 8 Seconds')),
                        DropdownMenuItem(value: 12, child: Text('Automatic - Every 12 Seconds')),
                      ],
                      onChanged: (val) => setDialogState(() => autoInterval = val),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx, {
                      'title': titleController.text.trim(),
                      'interval': autoInterval,
                    });
                  },
                  child: const Text('Create Game', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && mounted) {
      setState(() => _isActionLoading = true);
      try {
        final game = await TambolaApiService.createGame(
          title: result['title'] as String?,
          autoDrawInterval: result['interval'] as int?,
        );
        if (!mounted) return;
        setState(() => _isActionLoading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TambolaGameRoomPage(roomCode: game.roomCode),
          ),
        ).then((_) => _fetchGames(silent: true));
      } catch (e) {
        if (!mounted) return;
        setState(() => _isActionLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red.shade700, content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canHost = AuthStorage.isHr || AuthStorage.isSuperAdmin;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text('🎟️ Company Tambola Hub', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        ),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _fetchGames(),
            tooltip: 'Refresh Games',
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4338CA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4338CA).withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.stars_rounded, color: Color(0xFFF59E0B), size: 14),
                              SizedBox(width: 4),
                              Text(
                                'MULTIPLAYER HOUSIE',
                                style: TextStyle(color: Color(0xFFFBBF24), fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'HR Team Tambola Lounge 🎉',
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Join an active room or enter a code to play real-time Housie with your colleagues!',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Quick Join / Host Toolbar
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 540;
                    final joinBox = Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.vpn_key_rounded, color: Color(0xFFF59E0B), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _roomCodeController,
                              textCapitalization: TextCapitalization.characters,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'ROOM CODE',
                                hintStyle: TextStyle(fontSize: 12, letterSpacing: 1.0),
                                border: InputBorder.none,
                              ),
                              onSubmitted: (val) => _handleJoinGame(val),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B82F6),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                            onPressed: () => _handleJoinGame(),
                            child: const FittedBox(fit: BoxFit.scaleDown, child: Text('JOIN', style: TextStyle(fontWeight: FontWeight.bold))),
                          ),
                        ],
                      ),
                    );

                    final hostBtn = canHost
                        ? ElevatedButton.icon(
                            icon: const Icon(Icons.add_rounded, size: 20),
                            label: const FittedBox(fit: BoxFit.scaleDown, child: Text('HOST GAME', style: TextStyle(fontWeight: FontWeight.bold))),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B),
                              foregroundColor: const Color(0xFF0F172A),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              elevation: 2,
                            ),
                            onPressed: _showCreateGameDialog,
                          )
                        : null;

                    if (isCompact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          joinBox,
                          if (hostBtn != null) ...[
                            const SizedBox(height: 12),
                            hostBtn,
                          ],
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: joinBox),
                        if (hostBtn != null) ...[
                          const SizedBox(width: 12),
                          hostBtn,
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Active Games Section
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Live & Waiting Rooms',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_games.length}',
                        style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_errorMessage != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        children: [
                          Icon(Icons.cloud_off_rounded, color: Colors.grey.shade400, size: 48),
                          const SizedBox(height: 12),
                          Text(_errorMessage!, style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 12),
                          ElevatedButton(onPressed: _fetchGames, child: const Text('Retry')),
                        ],
                      ),
                    ),
                  )
                else if (_games.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.sports_esports_outlined, size: 54, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'No Active Games Right Now',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Be the first to host a game or ask your HR manager to start a session!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        if (canHost) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('HOST A GAME NOW'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B),
                              foregroundColor: const Color(0xFF0F172A),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _showCreateGameDialog,
                          ),
                        ],
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _games.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final game = _games[index];
                      return _buildGameCard(game, isDark);
                    },
                  ),
              ],
            ),
          ),
          if (_isActionLoading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFFF59E0B)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGameCard(TambolaGame game, bool isDark) {
    Color statusColor;
    String statusLabel;
    switch (game.status) {
      case 'RUNNING':
        statusColor = const Color(0xFF10B981);
        statusLabel = 'LIVE IN PROGRESS';
        break;
      case 'PAUSED':
        statusColor = const Color(0xFFF59E0B);
        statusLabel = 'PAUSED';
        break;
      default:
        statusColor = const Color(0xFF3B82F6);
        statusLabel = 'WAITING FOR PLAYERS';
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF312E81), Color(0xFF4338CA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: const Text('🎟️', style: TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          game.title,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(color: statusColor, fontSize: 9.5, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          'CODE: ${game.roomCode}',
                          style: const TextStyle(
                            color: Color(0xFFD97706),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Text(
                        'Host: ${game.createdByName}',
                        style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${game.playerCount} Players',
                        style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              onPressed: () => _handleJoinGame(game.roomCode),
              child: const Text('ENTER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}


