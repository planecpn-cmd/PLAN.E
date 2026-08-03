import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import { useSessionStore } from '@/stores/sessionStore';

export function useProfile() {
  const user = useSessionStore((state) => state.user);

  return useQuery({
    queryKey: ['profile', user?.id],
    queryFn: async () => {
      if (!user?.id) return null;
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', user.id)
        .single();

      if (error) throw error;
      return data;
    },
    enabled: !!user?.id,
  });
}
