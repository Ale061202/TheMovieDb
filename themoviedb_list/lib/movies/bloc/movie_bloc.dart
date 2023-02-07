import 'dart:async';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;
import 'package:stream_transform/stream_transform.dart';
import 'package:themoviedb_list/movies/models/models.dart';
import 'package:themoviedb_list/movies/models/popular_response.dart';
import 'package:themoviedb_list/movies/movies.dart';

part 'movie_event.dart';
part 'movie_state.dart';

const _postLimit = 20;
const throttleDuration = Duration(milliseconds: 100);

EventTransformer<E> throttleDroppable<E>(Duration duration){
  return (events, mapper){
    return droppable<E>().call(events.throttle(duration),mapper);
  };
}

class PostBloc extends Bloc<PostEvent, PostState> {
  PostBloc({required this.httpClient}) : super(const PostState()){
    on<PostFetched>(
      _onPostFetched,
      transformer: throttleDroppable(throttleDuration),
    );
  }

  final http.Client httpClient;

  Future<void> _onPostFetched(
    PostFetched event,
    Emitter<PostState> emit,
  ) async {
    if (state.hasReachedMax) return;
    try {
      if (state.status == PostStatus.initial) {
        final movies = await _fetchPosts();
        return emit(
          state.copyWith(
            status: PostStatus.success,
            posts: movies,
            hasReachedMax: false,
          ),
        );
      }
      final movies = await _fetchPosts(state.posts.length);
      movies.isEmpty
          ? emit(state.copyWith(hasReachedMax: true))
          : emit(
              state.copyWith(
                status: PostStatus.success,
                posts: List.of(state.posts)..addAll(movies),
                hasReachedMax: false,
              ),
            );
    } catch (_) {
      emit(state.copyWith(status: PostStatus.failure));
    }
  }

  Future<List<Movie>> _fetchPosts([int startIndex = 0]) async {
    final response = await httpClient.get(
      Uri.https(
        'https://api.themoviedb.org/3/movie/popular?api_key=da2e18b310d36237778f0c5a83644622&language=es-ES&page=1',
        '/movies',
        <String, String>{'_start': '$startIndex', '_limit': '$_postLimit'},
      ),
    );
    if (response.statusCode == 200) {
      final body = json.decode(response.body) as List;
      return body.map((dynamic json) {
        final map = json as Map<String, dynamic>;
        return Movie(
          id: map['id'] as int,
          title: map['title'] as String,
          overview: map['body'] as String,          
          voteAverage: map['body'] as double,          
          adult: map['body'] as bool,          
          genreIds: map['body'] as List<int>,          
          originalLanguage: map['body'] as String,
          originalTitle: map['body'] as String,
          popularity: map['body'] as double,
          video: map['body'] as bool,
          voteCount: map['body'] as int,
          backdropPath: map['body'] as String,
          posterPath: map['body'] as String,
          releaseDate: map['body'] as String,
        );
      }).toList();
    }
    throw Exception('error fetching posts');
  }
}