import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/points_service.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  final String currentUserId;

  const LeaderboardScreen({
    super.key,
    required this.currentUserId,
  });

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _leaderboard = [];
  Map<String, dynamic>? _currentUserRank;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('points', descending: true)
          .limit(100)
          .get();

      final leaderboard = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Anonymous',
          'photoUrl': data['photoUrl'],
          'points': data['points'] ?? 0,
        };
      }).toList();

      // Find current user's rank
      final currentUserIndex = leaderboard.indexWhere(
        (user) => user['id'] == widget.currentUserId,
      );

      setState(() {
        _leaderboard = leaderboard;
        if (currentUserIndex != -1) {
          _currentUserRank = {
            ...leaderboard[currentUserIndex],
            'rank': currentUserIndex + 1,
          };
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load leaderboard: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildLeaderboardItem(Map<String, dynamic> user, int index) {
    final isCurrentUser = user['id'] == widget.currentUserId;
    final rank = index + 1;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isCurrentUser ? Colors.blue.withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 30,
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: rank <= 3 ? Colors.amber : Colors.grey,
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundImage: user['photoUrl'] != null
                  ? NetworkImage(user['photoUrl'])
                  : null,
              child: user['photoUrl'] == null
                  ? Text(user['name'][0].toUpperCase())
                  : null,
            ),
          ],
        ),
        title: Text(
          user['name'],
          style: TextStyle(
            fontWeight: isCurrentUser ? FontWeight.bold : null,
          ),
        ),
        trailing: Text(
          '${user['points']} pts',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: rank <= 3 ? Colors.amber : Colors.grey,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLeaderboard,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadLeaderboard,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    if (_currentUserRank != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.blue.withOpacity(0.1),
                        child: Row(
                          children: [
                            const Icon(Icons.emoji_events, color: Colors.amber),
                            const SizedBox(width: 8),
                            Text(
                              'Your Rank: #${_currentUserRank!['rank']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${_currentUserRank!['points']} pts',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                    ],
                    Expanded(
                      child: ListView.builder(
                        itemCount: _leaderboard.length,
                        itemBuilder: (context, index) {
                          return _buildLeaderboardItem(_leaderboard[index], index);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
} 