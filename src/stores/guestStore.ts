import { create } from 'zustand';

interface GuestState {
  guestId: string;
  selectedInterests: string[];
  setInterests: (interests: string[]) => void;
  toggleInterest: (interestId: string) => void;
}

export const useGuestStore = create<GuestState>((set) => ({
  guestId: `guest_${Math.random().toString(36).substr(2, 9)}`,
  selectedInterests: [],
  setInterests: (interests) => set({ selectedInterests: interests }),
  toggleInterest: (interestId) =>
    set((state) => {
      const exists = state.selectedInterests.includes(interestId);
      if (exists) {
        return {
          selectedInterests: state.selectedInterests.filter((id) => id !== interestId),
        };
      } else {
        return {
          selectedInterests: [...state.selectedInterests, interestId],
        };
      }
    }),
}));
