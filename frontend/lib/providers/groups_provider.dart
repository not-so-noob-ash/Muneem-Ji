import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/group_model.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

class GroupsState {
  final bool isLoading;
  final List<Group> groups;
  final String? errorMessage;

  GroupsState({
    this.isLoading = false,
    this.groups = const [],
    this.errorMessage,
  });

  GroupsState copyWith({
    bool? isLoading,
    List<Group>? groups,
    String? errorMessage,
  }) {
    return GroupsState(
      isLoading: isLoading ?? this.isLoading,
      groups: groups ?? this.groups,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class GroupsNotifier extends StateNotifier<GroupsState> {
  final ApiService _apiService;
  final String _token;

  GroupsNotifier(this._apiService, this._token) : super(GroupsState()) {
    if (_token.isNotEmpty) {
      fetchGroups();
    }
  }

  Future<void> fetchGroups() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final groups = await _apiService.getGroups(token: _token);
      state = state.copyWith(isLoading: false, groups: groups);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> createGroup(String name) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _apiService.createGroup(token: _token, name: name);
      await fetchGroups(); // Refresh list
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

final groupsProvider = StateNotifierProvider<GroupsNotifier, GroupsState>((ref) {
  final apiService = ApiService();
  final token = ref.watch(authProvider).token ?? '';
  return GroupsNotifier(apiService, token);
});