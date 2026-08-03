import { create } from 'zustand';

export interface DeferredAction {
  screenId: string;
  entityId?: string;
  action: 'save_experience' | 'book_experience' | 'host_apply';
  params?: Record<string, any>;
}

interface DeferredActionState {
  pendingAction: DeferredAction | null;
  setPendingAction: (action: DeferredAction | null) => void;
  clearPendingAction: () => void;
}

export const useDeferredActionStore = create<DeferredActionState>((set) => ({
  pendingAction: null,
  setPendingAction: (action) => set({ pendingAction: action }),
  clearPendingAction: () => set({ pendingAction: null }),
}));
