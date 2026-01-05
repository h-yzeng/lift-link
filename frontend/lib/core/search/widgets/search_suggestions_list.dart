import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liftlink/core/search/search_history_provider.dart';

/// Widget that displays search suggestions based on query
class SearchSuggestionsList extends ConsumerWidget {
  final String query;
  final void Function(String) onSuggestionTap;

  const SearchSuggestionsList({
    super.key,
    required this.query,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionsAsync = ref.watch(
      searchSuggestionsProvider(query: query, limit: 5),
    );

    return suggestionsAsync.when<Widget>(
      data: (List<String> suggestions) {
        if (suggestions.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  query.isEmpty ? 'Recent Searches' : 'Suggestions',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              const Divider(height: 1),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: suggestions.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final String suggestion = suggestions[index];
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      query.isEmpty ? Icons.history : Icons.search,
                      size: 20,
                    ),
                    title: Text(suggestion),
                    onTap: () => onSuggestionTap(suggestion),
                  );
                },
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
