import 'package:flutter/material.dart';
import 'package:themoviedb_list/movies/movies.dart';

class PostListItem extends StatelessWidget {
  const PostListItem({super.key, required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      child: ListTile(
        leading: Text('${movie.id}', style: textTheme.bodySmall),
        title: Text(movie.title),
        isThreeLine: true,
        subtitle: Text(movie.overview),
        dense: true,
      ),
    );
  }
}
