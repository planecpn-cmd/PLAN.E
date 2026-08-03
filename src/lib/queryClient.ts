import { QueryClient } from '@tanstack/react-query';

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 2,
      staleTime: 60 * 1000, // 60 seconds
      refetchOnReconnect: true,
      refetchOnWindowFocus: false,
    },
  },
});
