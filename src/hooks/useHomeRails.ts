import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';

export function useHomeRails() {
  return useQuery({
    queryKey: ['homeRails'],
    queryFn: async () => {
      const { data: recommended, error: e1 } = await supabase
        .from('experiences')
        .select('*')
        .eq('status', 'published')
        .order('rating_avg', { ascending: false })
        .limit(6);

      const { data: trending, error: e2 } = await supabase
        .from('experiences')
        .select('*')
        .eq('status', 'published')
        .order('rating_count', { ascending: false })
        .limit(6);

      if (e1) throw e1;
      if (e2) throw e2;

      return {
        recommended: recommended || [],
        trending: trending || [],
      };
    },
  });
}
