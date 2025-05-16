import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sifter/models/chat_room.dart';
import 'package:sifter/services/room_service.dart';
import 'package:sifter/utils/error_handler.dart';

part 'room_provider.g.dart';

@riverpod
class RoomNotifier extends _$RoomNotifier {
  late final RoomService _roomService;
  
  @override
  FutureOr<List<ChatRoom>> build() {
    _roomService = ref.watch(roomServiceProvider);
    return _fetchRooms();
  }
  
  Future<List<ChatRoom>> _fetchRooms() async {
    try {
      return await _roomService.fetchNearbyRooms();
    } catch (e, stack) {
      ErrorHandler.logError(e, stack);
      throw Exception('Failed to fetch rooms: ${e.toString()}');
    }
  }
  
  // Create a new room
  Future<ChatRoom> createRoom(ChatRoom room) async {
    state = const AsyncValue.loading();
    
    try {
      final newRoom = await _roomService.createRoom(room);
      
      // Refresh the room list
      state = AsyncValue.data([...state.value ?? [], newRoom]);
      return newRoom;
    } catch (e, stack) {
      ErrorHandler.logError(e, stack);
      state = AsyncError(e, stack);
      throw Exception('Failed to create room: ${e.toString()}');
    }
  }
  
  // Update an existing room
  Future<void> updateRoom(ChatRoom updatedRoom) async {
    try {
      await _roomService.updateRoom(updatedRoom);
      
      // Update the room in the local state
      state = AsyncValue.data(
        state.value?.map((room) => 
          room.id == updatedRoom.id ? updatedRoom : room
        ).toList() ?? []
      );
    } catch (e, stack) {
      ErrorHandler.logError(e, stack);
      throw Exception('Failed to update room: ${e.toString()}');
    }
  }
  
  // Join a room
  Future<void> joinRoom(String roomId, String userId) async {
    try {
      await _roomService.joinRoom(roomId, userId);
      
      // Update room in local state
      final updatedRooms = await _fetchRooms();
      state = AsyncValue.data(updatedRooms);
    } catch (e, stack) {
      ErrorHandler.logError(e, stack);
      throw Exception('Failed to join room: ${e.toString()}');
    }
  }
  
  // Leave a room
  Future<void> leaveRoom(String roomId, String userId) async {
    try {
      await _roomService.leaveRoom(roomId, userId);
      
      // Update room in local state
      final updatedRooms = await _fetchRooms();
      state = AsyncValue.data(updatedRooms);
    } catch (e, stack) {
      ErrorHandler.logError(e, stack);
      throw Exception('Failed to leave room: ${e.toString()}');
    }
  }
  
  // Delete a room
  Future<void> deleteRoom(String roomId) async {
    try {
      await _roomService.deleteRoom(roomId);
      
      // Remove room from local state
      state = AsyncValue.data(
        state.value?.where((room) => room.id != roomId).toList() ?? []
      );
    } catch (e, stack) {
      ErrorHandler.logError(e, stack);
      throw Exception('Failed to delete room: ${e.toString()}');
    }
  }
  
  // Refresh rooms
  Future<void> refreshRooms() async {
    state = const AsyncValue.loading();
    
    try {
      final rooms = await _fetchRooms();
      state = AsyncValue.data(rooms);
    } catch (e, stack) {
      ErrorHandler.logError(e, stack);
      state = AsyncError(e, stack);
    }
  }
}

// Provider for a specific room
@riverpod
Future<ChatRoom> room(RoomRef ref, String roomId) async {
  final roomService = ref.watch(roomServiceProvider);
  try {
    return await roomService.getRoom(roomId);
  } catch (e, stack) {
    ErrorHandler.logError(e, stack);
    throw Exception('Failed to fetch room: ${e.toString()}');
  }
}

// Room Service Provider
@riverpod
RoomService roomService(RoomServiceRef ref) {
  return RoomService();
} 