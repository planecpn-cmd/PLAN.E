import { create } from 'zustand';
import { UserRole } from '@/types/database';

interface UserProfile {
  id: string;
  fullName: string | null;
  email?: string | null;
  phone?: string | null;
  avatarUrl?: string | null;
  role: UserRole;
  points: number;
}

interface SessionState {
  user: UserProfile | null;
  role: UserRole;
  isAuthenticated: boolean;
  setSession: (user: UserProfile | null) => void;
  clearSession: () => void;
}

export const useSessionStore = create<SessionState>((set) => ({
  user: null,
  role: 'traveler',
  isAuthenticated: false,
  setSession: (user) =>
    set({
      user,
      role: user?.role || 'traveler',
      isAuthenticated: !!user,
    }),
  clearSession: () =>
    set({
      user: null,
      role: 'traveler',
      isAuthenticated: false,
    }),
}));
