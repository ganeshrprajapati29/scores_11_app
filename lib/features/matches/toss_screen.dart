import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/match_service.dart'; // Create this service
import '../../data/models/match_model.dart';
import '../matches/live_score_control_screen.dart';

class TossScreen extends StatefulWidget {
  final String matchId;
  const TossScreen({super.key, required this.matchId});

  @override
  State<TossScreen> createState() => _TossScreenState();
}

class _TossScreenState extends State<TossScreen> {
  String? selectedDecision;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text('Toss', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: Colors.white)),
        backgroundColor: const Color(0xFF0D2147),
        elevation: 0,
      ),
      body: FutureBuilder<Match>(
        future: MatchService().getMatch(widget.matchId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Match not found'));
          }
          final match = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Match Info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF1A56DB), Color(0xFF3B82F6)]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text('${match.team1.name} vs ${match.team2.name}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(match.format.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Toss Info
                const Text('Captains toss coin and winner chooses:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 24),
                // Choice Cards
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: selectedDecision == 'bat' ? null : () => setState(() => selectedDecision = 'bat'),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: selectedDecision == 'bat' ? Colors.green.shade50 : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selectedDecision == 'bat' ? Colors.green : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.bat, size: 48, color: selectedDecision == 'bat' ? Colors.green : Colors.grey.shade600),
                              const SizedBox(height: 12),
                              const Text('Bat First', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Text('Chase target', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: selectedDecision == 'bowl' ? null : () => setState(() => selectedDecision = 'bowl'),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: selectedDecision == 'bowl' ? Colors.orange.shade50 : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selectedDecision == 'bowl' ? Colors.orange : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.sports_cricket, size: 48, color: selectedDecision == 'bowl' ? Colors.orange : Colors.grey.shade600),
                              const SizedBox(height: 12),
                              const Text('Bowl First', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Text('Set target', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                // Winner selection
                const Text('Select toss winner:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: Icon(Icons.emoji_events, size: 20),
                        label: Text(match.team1.shortName ?? match.team1.name ?? 'Team 1'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF1A56DB),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: Icon(Icons.emoji_events, size: 20),
                        label: Text(match.team2.shortName ?? match.team2.name ?? 'Team 2'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF3B82F6),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectedDecision == null || isLoading ? null : _submitToss,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isLoading 
                      ? const SizedBox(
                          height: 20, 
                          width: 20, 
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                        )
                      : const Text('Complete Toss', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _submitToss() async {
    if (selectedDecision == null) return;
    
    setState(() => isLoading = true);
    
    try {
      // TODO: Call backend API
      // await MatchService().updateToss(widget.matchId, {
      //   winner: winnerTeamId, // select from teams
      //   decision: selectedDecision,
      // });
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Toss completed! Ready for live scoring.')),
        );
        // Navigate to live scoring
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LiveScoreControlScreen(matchId: widget.matchId),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (context.mounted) setState(() => isLoading = false);
    }
  }
}

