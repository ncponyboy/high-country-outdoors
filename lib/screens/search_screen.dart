import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/trail.dart';
import '../services/trail_service.dart';
import '../widgets/trail_row.dart';
import 'trail_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Trail> _search(List<Trail> trails) {
    if (_query.trim().isEmpty) return [];
    final q = _query.toLowerCase();
    return trails.where((t) {
      return t.name.toLowerCase().contains(q) ||
          t.parkForest.toLowerCase().contains(q) ||
          t.region.label.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D3A1A),
        foregroundColor: Colors.white,
        title: const Text(
          'Search',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: TextField(
              controller: _controller,
              autofocus: false,
              style: const TextStyle(color: Colors.black87, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Search trails, parks, forests...',
                hintStyle:
                    TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon:
                            const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() => _query = value);
              },
            ),
          ),
        ),
      ),
      body: Consumer<TrailService>(
        builder: (context, trailSvc, _) {
          if (trailSvc.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_query.trim().isEmpty) {
            return _EmptySearchState();
          }

          final results = _search(trailSvc.trails);

          if (results.isEmpty) {
            return _NoResults(query: _query);
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final trail = results[index];
              return Column(
                children: [
                  TrailRow(
                    trail: trail,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TrailDetailScreen(trail: trail),
                        ),
                      );
                    },
                  ),
                  if (index < results.length - 1)
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 16,
                      color: Colors.grey.shade200,
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty States
// ---------------------------------------------------------------------------

class _EmptySearchState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Search Trails',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Find trails by name, park, or forest.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  final String query;
  const _NoResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No results for "$query"',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different trail name or park.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
