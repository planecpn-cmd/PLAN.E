import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import { useSessionStore } from '@/stores/sessionStore';

export function useSaved() {
  const user = useSessionStore((state) => state.user);

  return useQuery({
    queryKey: ['savedExperiences', user?.id],
    queryFn: async () => {
      if (!user?.id) return [];
      const { data, error } = await supabase
        .from('saved_experiences')
        .select(`
          experience_id,
          experiences (*)
        `)
        .eq('user_id', user.id);

      if (error) throw error;
      return data;
    },
    enabled: !!user?.id,
  });
}
