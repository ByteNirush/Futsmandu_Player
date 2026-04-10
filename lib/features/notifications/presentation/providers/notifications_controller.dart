import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/player_notification_models.dart';
import '../../data/services/player_notifications_service.dart';

final notificationsServiceProvider = Provider<PlayerNotificationsService>((ref) {
  return PlayerNotificationsService.instance;
});

final notificationsControllerProvider = StateNotifierProvider.autoDispose<
    NotificationsController,
    NotificationsState>((ref) {
  return NotificationsController(ref.read(notificationsServiceProvider))
    ..loadInitial();
});

class NotificationsState {
  const NotificationsState({
    this.items = const <PlayerNotification>[],
    this.page = 1,
    this.pageSize = 20,
    this.hasMore = true,
    this.isLoadingInitial = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.isMarkingAllRead = false,
    this.errorMessage,
  });

  final List<PlayerNotification> items;
  final int page;
  final int pageSize;
  final bool hasMore;
  final bool isLoadingInitial;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool isMarkingAllRead;
  final String? errorMessage;

  NotificationsState copyWith({
    List<PlayerNotification>? items,
    int? page,
    int? pageSize,
    bool? hasMore,
    bool? isLoadingInitial,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? isMarkingAllRead,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return NotificationsState(
      items: items ?? this.items,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
      isLoadingInitial: isLoadingInitial ?? this.isLoadingInitial,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isMarkingAllRead: isMarkingAllRead ?? this.isMarkingAllRead,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class NotificationsController extends StateNotifier<NotificationsState> {
  NotificationsController(this._service) : super(const NotificationsState());

  final PlayerNotificationsService _service;

  Future<void> loadInitial() async {
    if (state.isLoadingInitial) return;

    state = state.copyWith(
      isLoadingInitial: true,
      clearErrorMessage: true,
    );

    try {
      final page = await _service.getNotifications(
        page: 1,
        limit: state.pageSize,
      );

      state = state.copyWith(
        items: page.items,
        page: 1,
        hasMore: page.hasMore,
        isLoadingInitial: false,
      );
    } on NotificationsApiException catch (e) {
      state = state.copyWith(
        isLoadingInitial: false,
        errorMessage: e.message,
      );
    } catch (_) {
      state = state.copyWith(
        isLoadingInitial: false,
        errorMessage: 'Failed to load notifications',
      );
    }
  }

  Future<void> refresh() async {
    if (state.isRefreshing) return;

    state = state.copyWith(
      isRefreshing: true,
      clearErrorMessage: true,
    );

    try {
      final page = await _service.getNotifications(
        page: 1,
        limit: state.pageSize,
      );

      state = state.copyWith(
        items: page.items,
        page: 1,
        hasMore: page.hasMore,
        isRefreshing: false,
      );
    } on NotificationsApiException catch (e) {
      state = state.copyWith(
        isRefreshing: false,
        errorMessage: e.message,
      );
    } catch (_) {
      state = state.copyWith(
        isRefreshing: false,
        errorMessage: 'Failed to refresh notifications',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || state.isLoadingInitial || !state.hasMore) {
      return;
    }

    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.page + 1;

    try {
      final page = await _service.getNotifications(
        page: nextPage,
        limit: state.pageSize,
      );

      state = state.copyWith(
        items: _deduplicateById([...state.items, ...page.items]),
        page: nextPage,
        hasMore: page.hasMore,
        isLoadingMore: false,
      );
    } on NotificationsApiException catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: e.message,
      );
    } catch (_) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: 'Failed to load more notifications',
      );
    }
  }

  Future<void> markAllRead() async {
    if (state.isMarkingAllRead || state.items.isEmpty) return;

    final previous = state.items;
    state = state.copyWith(
      isMarkingAllRead: true,
      items: previous
          .map((item) => item.isRead ? item : item.copyWith(isRead: true))
          .toList(growable: false),
      clearErrorMessage: true,
    );

    try {
      await _service.markAllRead();
      state = state.copyWith(isMarkingAllRead: false);
    } on NotificationsApiException catch (e) {
      state = state.copyWith(
        items: previous,
        isMarkingAllRead: false,
        errorMessage: e.message,
      );
      rethrow;
    } catch (_) {
      state = state.copyWith(
        items: previous,
        isMarkingAllRead: false,
        errorMessage: 'Failed to mark all notifications as read',
      );
      rethrow;
    }
  }

  Future<void> markRead(String notificationId) async {
    if (notificationId.isEmpty) return;

    final index =
        state.items.indexWhere((item) => item.id == notificationId);
    if (index == -1) return;

    final item = state.items[index];
    if (item.isRead) return;

    final updated = [...state.items];
    updated[index] = item.copyWith(isRead: true);
    state = state.copyWith(items: updated, clearErrorMessage: true);

    try {
      await _service.markOneRead(notificationId: notificationId);
    } on NotificationsApiException catch (e) {
      final rollback = [...state.items];
      rollback[index] = item;
      state = state.copyWith(items: rollback, errorMessage: e.message);
      rethrow;
    } catch (_) {
      final rollback = [...state.items];
      rollback[index] = item;
      state = state.copyWith(
        items: rollback,
        errorMessage: 'Failed to mark notification as read',
      );
      rethrow;
    }
  }

  List<PlayerNotification> _deduplicateById(List<PlayerNotification> input) {
    final seen = <String>{};
    final result = <PlayerNotification>[];

    for (final item in input) {
      if (item.id.isEmpty) {
        result.add(item);
        continue;
      }
      if (seen.add(item.id)) {
        result.add(item);
      }
    }

    return result;
  }
}