import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import { Database } from '@/types/database';

type Experience = Database['public']['Tables']['experiences']['Row'];

interface ExperienceFilters {
  categoryId?: string;
  regionId?: string;
  difficulty?: string;
  searchQuery?: string;
}

export function useExperiences(filters?: ExperienceFilters) {
  return useQuery({
    queryKey: ['experiences', filters],
    queryFn: async () => {
      let query = supabase
        .from('experiences')
        .select('*')
        .eq('status', 'published');

      if (filters?.categoryId) {
        query = query.eq('category_id', filters.categoryId);
      }
      if (filters?.regionId) {
        query = query.eq('region_id', filters.regionId);
      }
      if (filters?.difficulty) {
        query = query.eq('difficulty', filters.difficulty as any);
      }
      if (filters?.searchQuery) {
        query = query.textSearch('search_tsv', filters.searchQuery);
      }

      const { data, error } = await query.order('created_at', { ascending: false });
      if (error) throw error;
      return data as Experience[];
    },
  });
}
