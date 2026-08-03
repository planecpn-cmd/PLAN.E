import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';

export function useRegions() {
  return useQuery({
    queryKey: ['regions'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('regions')
        .select('*')
        .order('sort_order', { ascending: true });

      if (error) throw error;
      return data;
    },
  });
}
