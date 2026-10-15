import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/router/app_router.dart';
import '../../../../core/services/progress_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/celebration_overlay.dart';
import '../../../../core/widgets/mascot_widget.dart';
import '../../../../core/mascot/mascot_mood.dart';
import '../../../../core/widgets/parental_gate.dart';
import '../../../../core/settings/presentation/pages/settings_page.dart';

/// Owlie's Sanctuary: Dress-up wardrobe, Room decoration, Daily Missions,
/// Festive Themes (Eid, Ramzan, Christmas), and Parent Certificate!
class OwlieRoomPage extends StatefulWidget {
  const OwlieRoomPage({super.key});

  @override
  State<OwlieRoomPage> createState() => _OwlieRoomPageState();
}

class _OwlieRoomPageState extends State<OwlieRoomPage> {
  int _selectedHat = 0;
  int _selectedRoom = 0;
  String _selectedFestival = 'Eid';
  bool _missionCompleted = false;

  final List<Map<String, dynamic>> _hats = <Map<String, dynamic>>[
    <String, dynamic>{'name': 'Party Hat', 'emoji': '🥳'},
    <String, dynamic>{'name': 'Crown', 'emoji': '👑'},
    <String, dynamic>{'name': 'Detective', 'emoji': '🕵️'},
    <String, dynamic>{'name': 'Graduation', 'emoji': '🎓'},
    <String, dynamic>{'name': 'Festive', 'emoji': '🌙'},
    <String, dynamic>{'name': 'Wizard', 'emoji': '🧙'},
  ];

  final List<Map<String, dynamic>> _rooms = <Map<String, dynamic>>[
    <String, dynamic>{'name': 'Sunny Garden', 'color': Color(0xFFD6F2D9), 'icon': '🌻'},
    <String, dynamic>{'name': 'Starry Sky', 'color': Color(0xFFDCEAFE), 'icon': '✨'},
    <String, dynamic>{'name': 'Candy Land', 'color': Color(0xFFFDE8E8), 'icon': '🍭'},
    <String, dynamic>{'name': 'Cozy Nest', 'color': Color(0xFFFEF3C7), 'icon': '🪺'},
  ];

  @override
  Widget build(BuildContext context) {
    final ProgressService progress = di.sl<ProgressService>();

    return Scaffold(
      backgroundColor: _rooms[_selectedRoom]['color'] as Color,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          children: <Widget>[
            // Header with title and Grown-up settings gear
            Row(
              children: <Widget>[
                const Text(
                  "Owlie's World",
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF23314E),
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Grown-up Settings',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.all(10),
                  ),
                  icon: const Icon(Icons.settings_rounded, color: Color(0xFF4C3FB5)),
                  onPressed: () async {
                    final bool ok = await showParentalGate(context);
                    if (ok && context.mounted) {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (BuildContext ctx) => const SettingsPage(),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Owlie Stage: Large Mascot in Room with selected Hat
            Center(
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: <Widget>[
                  // Mascot with tap reaction
                  GestureDetector(
                    onTap: () {
                      showCelebrationOverlay(
                        context,
                        message: "Owlie loves you! Twit-twoo! 🎉",
                      );
                    },
                    child: const MascotWidget(
                      mood: MascotMood.excited,
                      size: 150,
                      talking: false,
                    ),
                  ),
                  // Hat floating on Owlie's head
                  Positioned(
                    top: -12,
                    child: Text(
                      _hats[_selectedHat]['emoji'] as String,
                      style: const TextStyle(fontSize: 44),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Wearing: ${_hats[_selectedHat]['name']} ${_hats[_selectedHat]['emoji']}',
                  style: const TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF455582),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Section 1: Dress Owlie & Decorate Room
            _buildSectionCard(
              title: '🦉 Dress Owlie & Decorate Room',
              subtitle: 'Use your collected stars to style Owlie!',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Pick a Hat / Outfit:',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 52,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _hats.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (BuildContext context, int index) {
                        final bool active = _selectedHat == index;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedHat = index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: active ? const Color(0xFF4C3FB5) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: active ? const Color(0xFF4C3FB5) : const Color(0xFFE2E8F0),
                                width: 2,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              children: <Widget>[
                                Text(_hats[index]['emoji'] as String, style: const TextStyle(fontSize: 22)),
                                const SizedBox(width: 6),
                                Text(
                                  _hats[index]['name'] as String,
                                  style: TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: active ? Colors.white : const Color(0xFF334155),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Change Room Background:',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List<Widget>.generate(_rooms.length, (int i) {
                      final bool active = _selectedRoom == i;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedRoom = i),
                          child: Container(
                            margin: EdgeInsets.only(right: i < _rooms.length - 1 ? 6 : 0),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _rooms[i]['color'] as Color,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: active ? const Color(0xFF4C3FB5) : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                            child: Column(
                              children: <Widget>[
                                Text(_rooms[i]['icon'] as String, style: const TextStyle(fontSize: 18)),
                                const SizedBox(height: 2),
                                Text(
                                  _rooms[i]['name'] as String,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section 2: Daily Mission & Weekly Challenge
            _buildSectionCard(
              title: '🎯 Daily Mission & Weekly Challenge',
              subtitle: 'Roz khelo, roz naye inamaat pao!',
              child: Column(
                children: <Widget>[
                  _buildMissionTile(
                    title: 'Daily Mission: Hal karo 3 Animal Puzzles',
                    subtitle: 'Progress: ${progress.solvedPuzzleCount.clamp(0, 3)}/3 completed',
                    isDone: _missionCompleted || progress.solvedPuzzleCount >= 3,
                    onClaim: () {
                      setState(() => _missionCompleted = true);
                      showCelebrationOverlay(
                        context,
                        message: 'Mubarak ho! 5 Bonus Stars & 1 New Sticker unlock hua!',
                      );
                    },
                  ),
                  const Divider(height: 18, color: Color(0xFFF1F5F9)),
                  _buildMissionTile(
                    title: 'Weekly Challenge: Seekho 5 Letters',
                    subtitle: 'Letters explored: ${progress.exploredCount}/5',
                    isDone: progress.exploredCount >= 5,
                    onClaim: () {
                      showCelebrationOverlay(
                        context,
                        message: 'Weekly Champion! Owlie ka Golden Crown unlock hua!',
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section 3: Festive Special Events (Eid, Ramzan, Christmas)
            _buildSectionCard(
              title: '🎉 Festival Specials',
              subtitle: 'Tehwaron par khaas tyari aur rang!',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <String>['Eid', 'Ramadan', 'Christmas', 'Halloween'].map((String fest) {
                      final bool active = _selectedFestival == fest;
                      return ChoiceChip(
                        label: Text(
                          switch (fest) {
                            'Eid' => '🌙 Eid Mubarak',
                            'Ramadan' => '🕌 Ramadan Kareem',
                            'Christmas' => '🎄 Merry Christmas',
                            _ => '🎃 Halloween Fun',
                          },
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 13,
                            color: active ? Colors.white : const Color(0xFF334155),
                          ),
                        ),
                        selected: active,
                        selectedColor: const Color(0xFF36C774),
                        backgroundColor: const Color(0xFFF1F5F9),
                        onSelected: (_) => setState(() => _selectedFestival = fest),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$_selectedFestival theme enabled! Enjoy sparkling festive stars & themed puzzles.',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section 4: Child's Learning Certificate for Parents
            _buildSectionCard(
              title: '📜 Certificate of Achievement',
              subtitle: 'Bachay k kaam ka certificate jo parents share kar sakein!',
              child: Column(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEFCE8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFDE047), width: 2),
                    ),
                    child: Column(
                      children: <Widget>[
                        const Text(
                          '🌟 OWLIE SUPER LEARNER 🌟',
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFB45309),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'This certifies that our Little Champion has explored:',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: 'Nunito', fontSize: 13, color: Color(0xFF451A03)),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            _buildCertStat('⭐ Stars', '${progress.totalStars}'),
                            _buildCertStat('🔤 Letters', '${progress.exploredCount}'),
                            _buildCertStat('🦁 Puzzles', '${progress.solvedPuzzleCount}'),
                            _buildCertStat('🔥 Streak', '${progress.streakDays}d'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4C3FB5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.share_rounded, size: 20),
                      label: const Text(
                        'Share Certificate with Family',
                        style: TextStyle(fontFamily: 'Fredoka', fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      onPressed: () {
                        showCelebrationOverlay(
                          context,
                          message: 'Certificate saved! Proud moments for Parents & Kids! 🌟',
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildMissionTile({
    required String title,
    required String subtitle,
    required bool isDone,
    required VoidCallback onClaim,
  }) {
    return Row(
      children: <Widget>[
        Icon(
          isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          color: isDone ? const Color(0xFF36C774) : const Color(0xFF94A3B8),
          size: 26,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isDone ? const Color(0xFF36C774) : const Color(0xFFF1F5F9),
            foregroundColor: isDone ? Colors.white : const Color(0xFF94A3B8),
            elevation: isDone ? 2 : 0,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: isDone ? onClaim : null,
          child: Text(
            isDone ? 'Claim' : 'Play',
            style: const TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCertStat(String label, String value) {
    return Column(
      children: <Widget>[
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Fredoka',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
