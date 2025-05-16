import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sifter/services/room_service.dart';

class RoomProvider with ChangeNotifier {
  final RoomService _roomService = RoomService();

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  Stream<QuerySnapshot> getUserRooms(String userId) {
    return _roomService.getUserRooms(userId);
  }

  Future<void> createRoom({
    required String name,
    required String creatorId,
    String? description,
    bool isPrivate = false,
    List<String>? members,
  }) async {
    _setLoading(true);
    try {
      await _roomService.createRoom(
        name: name,
        creatorId: creatorId,
        description: description,
        isPrivate: isPrivate,
        members: members,
      );
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateRoom({
    required String roomId,
    String? name,
    String? description,
    bool? isPrivate,
  }) async {
    _setLoading(true);
    try {
      await _roomService.updateRoom(
        roomId: roomId,
        name: name,
        description: description,
        isPrivate: isPrivate,
      );
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteRoom(String roomId) async {
    _setLoading(true);
    try {
      await _roomService.deleteRoom(roomId);
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addMember(String roomId, String userId) async {
    try {
      await _roomService.addMember(roomId, userId);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> removeMember(String roomId, String userId) async {
    try {
      await _roomService.removeMember(roomId, userId);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<List<String>> getRoomMembers(String roomId) async {
    return await _roomService.getRoomMembers(roomId);
  }

  Future<bool> isUserMember(String roomId, String userId) async {
    return await _roomService.isUserMember(roomId, userId);
  }

  Future<int> getUnreadCount(String roomId, String userId) async {
    return await _roomService.getUnreadCount(roomId, userId);
  }

  Future<void> markRoomAsRead(String roomId, String userId) async {
    try {
      await _roomService.markRoomAsRead(roomId, userId);
    } catch (e) {
      _setError(e.toString());
    }
  }
} 