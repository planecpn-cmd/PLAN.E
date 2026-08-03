import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import { useSessionStore } from '@/stores/sessionStore';
import { BookingStatus } from '@/types/database';

export function useBookings(status?: BookingStatus) {
  const user = useSessionStore((state) => state.user);

  return useQuery({
    queryKey: ['bookings', user?.id, status],
    queryFn: async () => {
      if (!user?.id) return [];
      let query = supabase
        .from('bookings')
        .select(`
          *,
          experiences (*),
          experience_departures (*)
        `)
        .eq('user_id', user.id);

      if (status) {
        query = query.eq('status', status);
      }

      const { data, error } = await query.order('created_at', { ascending: false });
      if (error) throw error;
      return data;
    },
    enabled: !!user?.id,
  });
}
