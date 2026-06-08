import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/save_slot.dart';
import 'meta_progress_provider.dart';
import 'run_provider.dart';

/// 세이브 슬롯 1·2·3을 리스트로 관리하는 Provider.
/// index 0 = 슬롯1, index 1 = 슬롯2, index 2 = 슬롯3.
final saveSlotProvider =
    NotifierProvider<SaveSlotNotifier, List<SaveSlot?>>(SaveSlotNotifier.new);

/// 세이브 슬롯 저장·로드·삭제를 담당하는 Notifier.
class SaveSlotNotifier extends Notifier<List<SaveSlot?>> {
  @override
  List<SaveSlot?> build() {
    final storage = ref.watch(localStorageProvider);
    return storage.loadAllSaveSlots();
  }

  /// 현재 런 상태를 [slotId] 슬롯에 저장한다.
  Future<void> saveToSlot(int slotId) async {
    final storage  = ref.read(localStorageProvider);
    final runState = ref.read(runProvider);

    await storage.saveSaveSlot(slotId, runState);

    final updated = List<SaveSlot?>.from(state);
    updated[slotId - 1] = storage.loadSaveSlot(slotId);
    state = List.unmodifiable(updated);
  }

  /// [slotId] 슬롯의 런 상태를 로드해 [RunNotifier]에 반영한다.
  Future<void> loadFromSlot(int slotId) async {
    final slot = ref.read(localStorageProvider).loadSaveSlot(slotId);
    if (slot == null) return;
    ref.read(runProvider.notifier).restoreFromSaveSlot(slot.runState);
  }

  /// [slotId] 슬롯을 삭제한다.
  Future<void> deleteSlot(int slotId) async {
    await ref.read(localStorageProvider).deleteSaveSlot(slotId);

    final updated = List<SaveSlot?>.from(state);
    updated[slotId - 1] = null;
    state = List.unmodifiable(updated);
  }
}
