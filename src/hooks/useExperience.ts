import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';

export function useExperience(id: string) {
  return useQuery({
    queryKey: ['experience', id],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('experiences')
        .select(`
          *,
          categories (*),
          regions (*),
          experience_departures (*),
          itinerary_items (*)
        `)
        .eq('id', id)
        .single();

      if (error) throw error;
      return data;
    },
    enabled: !!id,
  });
}
