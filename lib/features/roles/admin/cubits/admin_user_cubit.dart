import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/models.dart';
import '../../../../core/repositories.dart';

class AdminUserState extends Equatable {
  const AdminUserState({
    this.allUsers = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.lastDoc,
    this.error,
  });

  final List<AppUser> allUsers;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final DocumentSnapshot? lastDoc;
  final String? error;

  AdminUserState copyWith({
    List<AppUser>? allUsers,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    DocumentSnapshot? lastDoc,
    String? error,
  }) {
    return AdminUserState(
      allUsers: allUsers ?? this.allUsers,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      lastDoc: lastDoc ?? this.lastDoc,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    allUsers,
    isLoading,
    isLoadingMore,
    hasMore,
    lastDoc,
    error,
  ];
}

class AdminUserCubit extends Cubit<AdminUserState> {
  AdminUserCubit({required UserRepository userRepository})
    : _userRepository = userRepository,
      super(AdminUserState());

  final UserRepository _userRepository;
  void loadUsers({bool refresh = false}) async {
    if (refresh) {
      emit(state.copyWith(isLoading: true, hasMore: true, lastDoc: null));
    } else if (state.allUsers.isEmpty) {
      emit(state.copyWith(isLoading: true));
    }

    try {
      final (users, lastDoc) = await _userRepository.getUsers(limit: 20);
      emit(
        state.copyWith(
          allUsers: users,
          lastDoc: lastDoc,
          hasMore: users.length >= 20,
          isLoading: false,
        ),
      );
    } catch (e) {
      debugPrint("Error loading users: $e");
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  void loadMoreUsers() async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) return;

    emit(state.copyWith(isLoadingMore: true));

    try {
      final (users, lastDoc) = await _userRepository.getUsers(
        lastDoc: state.lastDoc,
        limit: 20,
      );

      final allUsers = List<AppUser>.from(state.allUsers)..addAll(users);

      emit(
        state.copyWith(
          allUsers: allUsers,
          lastDoc: lastDoc ?? state.lastDoc,
          hasMore: users.length >= 20,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      debugPrint("Error loading more users: $e");
      emit(state.copyWith(error: e.toString(), isLoadingMore: false));
    }
  }

  Future<void> updateRole(String userId, String role) async {
    await _userRepository.updateUserRole(userId, role);
    final idx = state.allUsers.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      final newUsers = List<AppUser>.from(state.allUsers);
      newUsers[idx] = newUsers[idx].copyWith(role: role);
      emit(state.copyWith(allUsers: newUsers));
    }
  }

  Future<void> toggleUserActive(String userId, bool isActive) async {
    await _userRepository.updateUserField(userId, 'isActive', isActive);
    final idx = state.allUsers.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      final newUsers = List<AppUser>.from(state.allUsers);
      newUsers[idx] = newUsers[idx].copyWith(isActive: isActive);
      emit(state.copyWith(allUsers: newUsers));
    }
  }

  Future<void> updateWalletBalance(String userId, double change) async {
    await _userRepository.updateWalletBalance(userId, change);
    // Optimistically update the UI if the user is in the list
    final idx = state.allUsers.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      final newUsers = List<AppUser>.from(state.allUsers);
      newUsers[idx] = newUsers[idx].copyWith(
        walletBalance: newUsers[idx].walletBalance + change,
      );
      emit(state.copyWith(allUsers: newUsers));
    }
  }
}
