import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pumpkin/features/feed/bloc/feed_event.dart';
import 'package:pumpkin/features/feed/bloc/feed_state.dart';
import 'package:pumpkin/services/feed_service.dart';

class FeedBloc extends Bloc<FeedEvent, FeedState> {
  final FeedService _feedService;
  int _currentPage = 0;
  static const int _postsPerPage = 10;

  FeedBloc({required FeedService feedService})
      : _feedService = feedService,
        super(const FeedInitial()) {
    on<LoadFeed>(_onLoadFeed);
    on<RefreshFeed>(_onRefreshFeed);
    on<LoadMorePosts>(_onLoadMorePosts);
  }

  Future<void> _onLoadFeed(LoadFeed event, Emitter<FeedState> emit) async {
    emit(const FeedLoading());
    try {
      _currentPage = 0;
      final posts = await _feedService.fetchPosts(
        page: _currentPage,
        limit: _postsPerPage,
      );
      
      emit(FeedLoaded(
        posts: posts,
        hasReachedMax: posts.length < _postsPerPage,
      ));
    } catch (e) {
      emit(FeedError(message: 'Failed to load posts: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshFeed(RefreshFeed event, Emitter<FeedState> emit) async {
    if (state is FeedLoaded) {
      final currentState = state as FeedLoaded;
      emit(FeedRefreshing(posts: currentState.posts));
    }
    
    try {
      _currentPage = 0;
      final posts = await _feedService.refreshPosts(limit: _postsPerPage);
      
      emit(FeedLoaded(
        posts: posts,
        hasReachedMax: posts.length < _postsPerPage,
      ));
    } catch (e) {
      if (state is FeedRefreshing) {
        final currentState = state as FeedRefreshing;
        emit(FeedLoaded(
          posts: currentState.posts,
          hasReachedMax: false,
        ));
      }
      emit(FeedError(message: 'Failed to refresh posts: ${e.toString()}'));
    }
  }

  Future<void> _onLoadMorePosts(LoadMorePosts event, Emitter<FeedState> emit) async {
    if (state is FeedLoaded) {
      final currentState = state as FeedLoaded;
      
      if (currentState.hasReachedMax) return;

      try {
        _currentPage++;
        final newPosts = await _feedService.fetchPosts(
          page: _currentPage,
          limit: _postsPerPage,
        );

        emit(currentState.copyWith(
          posts: List.from(currentState.posts)..addAll(newPosts),
          hasReachedMax: newPosts.length < _postsPerPage,
        ));
      } catch (e) {
        _currentPage--; // Rollback page increment on error
        emit(FeedError(message: 'Failed to load more posts: ${e.toString()}'));
      }
    }
  }
}
