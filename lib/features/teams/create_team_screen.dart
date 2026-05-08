import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../../data/services/team_service.dart';
import '../../../data/services/player_service.dart';
import '../../../data/models/player_model.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _kRadius = 14.0;
const _kCardRadius = 16.0;
const _kFieldGap = 14.0;
const _kBg = Color(0xFFF8F9FA);
const _kBorder = Color(0xFFEEEFF2);
const _kTextPrimary = Color(0xFF0D1117);
const _kTextSecondary = Color(0xFF6B7280);
const _kTextHint = Color(0xFF9CA3AF);
const _kShadow = Color(0x0A000000);

InputDecoration _fieldDeco({
  required String label,
  required IconData icon,
  String? hint,
  int? maxLines,
}) =>
    InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(fontSize: 13, color: _kTextHint),
      hintStyle: const TextStyle(fontSize: 13, color: _kTextHint),
      prefixIcon: Icon(icon, size: 18, color: _kTextHint),
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      alignLabelWithHint: (maxLines ?? 1) > 1,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: (maxLines ?? 1) > 1 ? 14 : 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kRadius),
        borderSide: const BorderSide(color: _kBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kRadius),
        borderSide: const BorderSide(color: _kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kRadius),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kRadius),
        borderSide: const BorderSide(color: Color(0xFFE53E3E)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kRadius),
        borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 1.5),
      ),
    );

// ─── Screen ───────────────────────────────────────────────────────────────────

class CreateTeamScreen extends StatefulWidget {
  const CreateTeamScreen({super.key});

  @override
  State<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends State<CreateTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _teamNameController = TextEditingController();
  final _teamCityController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _shortNameController = TextEditingController();
  final _coachController = TextEditingController();
  final _homeGroundController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController(text: 'India');

// Multiple players list - for adding multiple at once
  final List<Map<String, dynamic>> _playersList = [];
  final List<TextEditingController> _playerNameControllers = [];
  final List<TextEditingController> _playerJerseyControllers = [];
  final List<String> _playerRoles = [];
  
// Current player input fields
  String? _selectedPlayerRole = 'Batsman';
  final TextEditingController _playerNameController = TextEditingController();
  final TextEditingController _playerJerseyController = TextEditingController();
  
  // Player search state
  final TextEditingController _playerSearchController = TextEditingController();
  List<Player> _searchResults = [];
  bool _isSearching = false;
  
  bool _isLoading = false;
  bool _isCreatingPlayer = false;
  final TeamService _teamService = TeamService();
  final PlayerService _playerService = PlayerService();

// Add player to list - FIXED: Also save to backend immediately like website
  Future<void> _addPlayerToList() async {
    final name = _playerNameController.text.trim();
    if (name.isEmpty) return;
    
    setState(() => _isCreatingPlayer = true);
    
    try {
      // Create player in backend immediately (like website does)
      final player = await _playerService.createPlayer(
        name: name,
        role: _selectedPlayerRole,
        jerseyNumber: int.tryParse(_playerJerseyController.text.trim()),
      );
      
      // Add to local list with player ID from backend
      setState(() {
        _playersList.add({
          'name': name,
          'role': _selectedPlayerRole,
          'jersey': _playerJerseyController.text.trim(),
          'playerId': player.id, // Store player ID from backend
        });
        _playerNameController.clear();
        _playerJerseyController.clear();
      });
      
      _showSnack('$name saved to database!', isError: false);
    } catch (e) {
      _showSnack('Failed to save player: $e', isError: true);
    } finally {
      setState(() => _isCreatingPlayer = false);
    }
  }

  // Remove player from list
  void _removePlayerFromList(int index) {
    if (index >= 0 && index < _playersList.length) {
      setState(() {
        _playersList.removeAt(index);
      });
    }
  }

// Get filled players count
  int get _playerCount => _playersList.length;

  // Search players from database
  Future<void> _searchPlayers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    
    setState(() => _isSearching = true);
    
    try {
      final results = await _playerService.searchPlayers(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  // Add player from search results to team
  Future<void> _addExistingPlayer(Player player, String teamId) async {
    try {
      await _teamService.addPlayer(teamId, player.id);
      if (mounted) {
        _showSnack('${player.name} added to team!', isError: false);
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Failed to add player: $e', isError: true);
      }
    }
  }

@override
  void dispose() {
    _teamNameController.dispose();
    _shortNameController.dispose();
    _teamCityController.dispose();
    _stateController.dispose();
    _homeGroundController.dispose();
    _coachController.dispose();
    _descriptionController.dispose();
    _countryController.dispose();
    _playerNameController.dispose();
    _playerJerseyController.dispose();
    super.dispose();
  }

Future<void> _createTeam() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Step 1: Create the team
      final newTeam = await _teamService.createTeam(
        name: _teamNameController.text.trim(),
        shortName: _shortNameController.text.trim().isNotEmpty
            ? _shortNameController.text.trim()
            : null,
        city: _teamCityController.text.trim(),
        state: _stateController.text.trim().isNotEmpty
            ? _stateController.text.trim()
            : null,
        homeGround: _homeGroundController.text.trim().isNotEmpty
            ? _homeGroundController.text.trim()
            : null,
        coach: _coachController.text.trim().isNotEmpty
            ? _coachController.text.trim()
            : null,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        country: _countryController.text,
      );

      final teamId = newTeam.id;

      if (teamId == null) {
        throw Exception('Failed to create team - no team ID returned');
      }

      // Step 2: Save ALL players from _playersList to database
      if (_playersList.isNotEmpty) {
        setState(() => _isCreatingPlayer = true);
        
        int playersCreated = 0;
        int playersFailed = 0;
        
        for (int i = 0; i < _playersList.length; i++) {
          final playerData = _playersList[i];
          try {
            final jerseyNum = int.tryParse(playerData['jersey'].toString().trim());
            
            // Create player in database
            final player = await _playerService.createPlayer(
              name: playerData['name'].toString().trim(),
              role: playerData['role'].toString(),
              team: teamId,
              jerseyNumber: jerseyNum,
            );
            
            // Add player to team
            await _teamService.addPlayer(teamId, player.id);
            playersCreated++;
            
            // Small delay to avoid overwhelming the server
            await Future.delayed(const Duration(milliseconds: 100));
            
          } catch (e) {
            playersFailed++;
            debugPrint('Failed to create player ${playerData['name']}: $e');
          }
        }
        
        if (mounted) {
          if (playersCreated > 0) {
            _showSnack('Team & $playersCreated player(s) created!', isError: false);
          } else if (playersFailed > 0) {
            _showSnack('Team created but $playersFailed player(s) failed', isError: true);
          }
        }
        
        if (mounted) setState(() => _isCreatingPlayer = false);
      } 
      // Step 3: Also check if there's a player in the text fields (for backward compatibility)
      else if (_playerNameController.text.trim().isNotEmpty) {
        setState(() => _isCreatingPlayer = true);
        try {
          final jerseyNum = int.tryParse(_playerJerseyController.text.trim());
          final player = await _playerService.createPlayer(
            name: _playerNameController.text.trim(),
            role: _selectedPlayerRole,
            team: teamId,
            jerseyNumber: jerseyNum,
          );
          
          // Add player to team
          await _teamService.addPlayer(teamId, player.id);
          
          if (mounted) {
            _showSnack('Team & Player created!', isError: false);
          }
        } catch (e) {
          if (mounted) {
            _showSnack('Team created! (Player add failed: $e)', isError: false);
          }
        } finally {
          if (mounted) setState(() => _isCreatingPlayer = false);
        }
      } else {
        if (mounted) {
          _showSnack('Team created successfully!', isError: false);
        }
      }

      // Step 4: Navigate to add more players or match creation
      if (mounted && teamId != null) {
        if (context.mounted) {
          _showMatchCreationDialog(teamId);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Error: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Show dialog to create match after team creation
  void _showMatchCreationDialog(String teamId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _kBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Icon(Icons.sports_cricket_rounded,
                size: 48, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text(
              'What\'s Next?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _kTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add more players or create a match',
              style: TextStyle(fontSize: 14, color: _kTextSecondary),
            ),
            const SizedBox(height: 24),
            
            // Add Players Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/players/search',
                      arguments: {'teamId': teamId});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_kRadius)),
                ),
                icon: const Icon(Icons.person_add_rounded),
                label: const Text('Add More Players'),
              ),
            ),
            const SizedBox(height: 12),
            
            // Create Match Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/create-match',
                      arguments: {'teamId': teamId});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_kRadius)),
                ),
                icon: const Icon(Icons.sports_rounded),
                label: const Text('Create Match'),
              ),
            ),
            const SizedBox(height: 12),
            
            // Skip Button
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(
                    context, '/my-teams', (route) => false);
              },
              child: const Text('Skip for now'),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Text(msg, style: const TextStyle(fontSize: 13))),
          ],
        ),
        backgroundColor:
            isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
_buildPageHeader(),
              const SizedBox(height: 20),
_buildInstantPlayerCard(),
              const SizedBox(height: 16),
              _buildPlayerSearchCard(),
              const SizedBox(height: 16),
              _buildRequiredSection(),
              const SizedBox(height: 16),
              _buildOptionalSection(),
              const SizedBox(height: 24),
              _buildCreateButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ── AppBar ───────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            size: 18, color: _kTextPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Create Team',
        style: TextStyle(
          color: _kTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: _kBorder),
      ),
    );
  }

  // ── Page header ──────────────────────────────────────────────────────────────

  Widget _buildPageHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kCardRadius),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(color: _kShadow, blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.groups_rounded,
                color: AppColors.primary, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Build Your Team',
                  style: TextStyle(
                    color: _kTextPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Fill in the details to create your cricket team',
                  style: TextStyle(color: _kTextSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// ── Instant Player Card (Scores11 Style) ─────────────────────────────────

  Widget _buildInstantPlayerCard() {
    return _SectionCard(
      title: 'Quick Player Add',
      icon: Icons.person_add_rounded,
      child: Column(
        children: [
          // Player Name
          TextFormField(
            controller: _playerNameController,
            style: const TextStyle(fontSize: 13, color: _kTextPrimary),
            decoration: _fieldDeco(
              label: 'Player Name',
              icon: Icons.person_rounded,
              hint: 'e.g., Rohit Sharma',
            ),
          ),
          const SizedBox(height: _kFieldGap),
          
          // Role Dropdown
          DropdownButtonFormField<String>(
            value: _selectedPlayerRole,
            style: const TextStyle(fontSize: 13, color: _kTextPrimary),
            decoration: _fieldDeco(
              label: 'Player Role',
              icon: Icons.sports_cricket_rounded,
            ),
            items: const [
              DropdownMenuItem(value: 'Batsman', child: Text('Batsman')),
              DropdownMenuItem(value: 'Bowler', child: Text('Bowler')),
              DropdownMenuItem(value: 'All-Rounder', child: Text('All-Rounder')),
              DropdownMenuItem(value: 'Wicket Keeper', child: Text('Wicket Keeper')),
            ],
            onChanged: (v) => setState(() => _selectedPlayerRole = v ?? 'Batsman'),
          ),
          const SizedBox(height: _kFieldGap),
          
          // Jersey Number
          TextFormField(
            controller: _playerJerseyController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 13, color: _kTextPrimary),
            decoration: _fieldDeco(
              label: 'Jersey Number (Optional)',
              icon: Icons.numbers_rounded,
              hint: 'e.g., 10',
            ),
          ),
          const SizedBox(height: _kFieldGap),
          
          // Add Player Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () {
                if (_playerNameController.text.trim().isNotEmpty) {
                  _addPlayerToList();
                  _showSnack('Player added to list!', isError: false);
                } else {
                  _showSnack('Please enter player name', isError: true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_kRadius),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Player', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
          
          // Show added players count and list
          if (_playersList.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.people_rounded, size: 18, color: Color(0xFF3B82F6)),
                  const SizedBox(width: 8),
                  Text(
                    '${_playersList.length} player(s) added',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF1E40AF), fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _playersList.clear();
                      });
                      _showSnack('Cleared all players', isError: false);
                    },
                    child: const Text(
                      'Clear All',
                      style: TextStyle(fontSize: 12, color: Color(0xFF3B82F6), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // List of added players with remove buttons
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _playersList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final player = _playersList[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _kBorder),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          player['name'].toString().isNotEmpty 
                              ? player['name'][0].toString().toUpperCase() 
                              : '?',
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              player['name'].toString(),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${player['role']}${player['jersey'].toString().isNotEmpty ? ' • #${player['jersey']}' : ''}',
                              style: const TextStyle(fontSize: 11, color: _kTextSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFFDC2626)),
                        onPressed: () => _removePlayerFromList(index),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

// ── Player Search Card ──────────────────────────────────────────────────

  Widget _buildPlayerSearchCard() {
    return _SectionCard(
      title: 'Search Existing Players',
      icon: Icons.search_rounded,
      child: Column(
        children: [
          // Search Field
          TextFormField(
            controller: _playerSearchController,
            style: const TextStyle(fontSize: 13, color: _kTextPrimary),
            decoration: _fieldDeco(
              label: 'Search Players',
              icon: Icons.search_rounded,
              hint: 'Search by name...',
            ),
            onChanged: (value) {
              _searchPlayers(value);
            },
          ),
          const SizedBox(height: _kFieldGap),
          
          // Search Results or Loading
          if (_isSearching)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_searchResults.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _searchResults.length.clamp(0, 5),
              itemBuilder: (context, index) {
                final player = _searchResults[index];
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  title: Text(
                    player.name,
                    style: const TextStyle(fontSize: 13),
                  ),
                  subtitle: Text(
                    player.role ?? 'Unknown',
                    style: const TextStyle(fontSize: 11, color: _kTextSecondary),
                  ),
                  trailing: const Icon(Icons.add_circle_outline, size: 20),
                  onTap: () {
                    // Player selected - could be used for team creation later
                  },
                );
              },
            )
          else if (_playerSearchController.text.isNotEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No players found',
                style: TextStyle(color: _kTextSecondary, fontSize: 12),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Start typing to search players',
                style: TextStyle(color: _kTextHint, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  // ── Required fields card ─────────────────────────────────────────────────────

  Widget _buildRequiredSection() {
    return _SectionCard(
      title: 'Team Information',
      icon: Icons.emoji_events_rounded,
      child: Column(
        children: [
          // Team Name
          TextFormField(
            controller: _teamNameController,
            style: const TextStyle(fontSize: 13, color: _kTextPrimary),
            decoration: _fieldDeco(
              label: 'Team Name *',
              icon: Icons.emoji_events_rounded,
              hint: 'e.g., Mumbai Warriors',
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Please enter team name';
              }
              if (v.trim().length < 3) {
                return 'Team name must be at least 3 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: _kFieldGap),

          // Short Name
          TextFormField(
            controller: _shortNameController,
            style: const TextStyle(fontSize: 13, color: _kTextPrimary),
            decoration: _fieldDeco(
              label: 'Short Name (Optional)',
              icon: Icons.short_text_rounded,
              hint: 'e.g., MW',
            ),
          ),
          const SizedBox(height: _kFieldGap),

          // City + State row
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _teamCityController,
                  style:
                      const TextStyle(fontSize: 13, color: _kTextPrimary),
                  decoration: _fieldDeco(
                    label: 'City',
                    icon: Icons.location_city_rounded,
                    hint: 'e.g., Mumbai',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _stateController,
                  style:
                      const TextStyle(fontSize: 13, color: _kTextPrimary),
                  decoration: _fieldDeco(
                    label: 'State',
                    icon: Icons.map_rounded,
                    hint: 'e.g., Maharashtra',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Optional fields card ─────────────────────────────────────────────────────

  Widget _buildOptionalSection() {
    return _SectionCard(
      title: 'Additional Details',
      icon: Icons.tune_rounded,
      child: Column(
        children: [
          // Home Ground
          TextFormField(
            controller: _homeGroundController,
            style: const TextStyle(fontSize: 13, color: _kTextPrimary),
            decoration: _fieldDeco(
              label: 'Home Ground',
              icon: Icons.stadium_rounded,
              hint: 'e.g., Wankhede Stadium',
            ),
          ),
          const SizedBox(height: _kFieldGap),

          // Coach
          TextFormField(
            controller: _coachController,
            style: const TextStyle(fontSize: 13, color: _kTextPrimary),
            decoration: _fieldDeco(
              label: 'Coach Name',
              icon: Icons.person_rounded,
              hint: 'e.g., Ravi Shastri',
            ),
          ),
          const SizedBox(height: _kFieldGap),

          // Country
          TextFormField(
            controller: _countryController,
            style: const TextStyle(fontSize: 13, color: _kTextPrimary),
            decoration: _fieldDeco(
              label: 'Country',
              icon: Icons.flag_rounded,
            ),
          ),
          const SizedBox(height: _kFieldGap),

          // Description
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            style: const TextStyle(fontSize: 13, color: _kTextPrimary),
            decoration: _fieldDeco(
              label: 'Description (Optional)',
              icon: Icons.description_rounded,
              hint: 'Tell us about your team…',
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }

  // ── Create button ────────────────────────────────────────────────────────────

  Widget _buildCreateButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createTeam,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_kRadius)),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.groups_rounded, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Create Team',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─── Reusable section card ────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kCardRadius),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(color: _kShadow, blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Icon(icon, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: _kTextPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: _kBorder),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}