const paths: Record<string, string> = {
  home: "M3 11.5 12 4l9 7.5M5 10v10h5v-6h4v6h5V10",
  compass:
    "M12 22c5.5 0 10-4.5 10-10S17.5 2 12 2 2 6.5 2 12s4.5 10 10 10Zm3.5-14.5-2 5.5-5.5 2 2-5.5 5.5-2Z",
  calendar:
    "M7 3v3M17 3v3M4 8h16M5 6h14a1 1 0 0 1 1 1v12a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V7a1 1 0 0 1 1-1Z",
  bookmark: "M6 3h12a1 1 0 0 1 1 1v17l-7-4-7 4V4a1 1 0 0 1 1-1Z",
  user: "M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8Zm-7 9a7 7 0 0 1 14 0",
  search: "M11 19a8 8 0 1 0 0-16 8 8 0 0 0 0 16Zm10 2-5.4-5.4",
  heart:
    "M12 21s-7.5-4.7-10-9.3C.4 8.1 2.3 4.5 6 4.5c2 0 3.5 1 6 3.4 2.5-2.4 4-3.4 6-3.4 3.7 0 5.6 3.6 4 7.2C19.5 16.3 12 21 12 21z",
  mapPin: "M12 22s7-7.4 7-12.5A7 7 0 0 0 5 9.5C5 14.6 12 22 12 22Zm0-9a3 3 0 1 0 0-6 3 3 0 0 0 0 6Z",
  chevronLeft: "m15 18-6-6 6-6",
  chevronRight: "m9 18 6-6-6-6",
  close: "M18 6 6 18M6 6l12 12",
  menu: "M4 7h16M4 12h16M4 17h16",
  bell: "M18 8a6 6 0 1 0-12 0c0 7-3 9-3 9h18s-3-2-3-9ZM13.7 21a2 2 0 0 1-3.4 0",
  spa: "M12 21c-4-1-6-4-6-8 0-3 2-6 6-10 4 4 6 7 6 10 0 4-2 7-6 8Zm0-13v9",
  route: "M4 19a3 3 0 1 0 0-6 3 3 0 0 0 0 6ZM20 11a3 3 0 1 0 0-6 3 3 0 0 0 0 6ZM7 16h4a4 4 0 0 0 4-4V9",
  lightbulb: "M9 18h6M10 21h4M12 3a6 6 0 0 0-3.5 10.9c.5.4.8 1 .8 1.6V16h5.4v-.5c0-.6.3-1.2.8-1.6A6 6 0 0 0 12 3Z",
  people: "M7 20v-1a4 4 0 0 1 4-4h2a4 4 0 0 1 4 4v1M9 9a3 3 0 1 0 0-6 3 3 0 0 0 0 6Zm6 0a3 3 0 1 0 0-6 3 3 0 0 0 0 6",
  restaurant: "M6 3v7a2 2 0 0 0 4 0V3M8 10v11M17 3c-1.5 1-2 3-2 5s.5 4 2 5v8",
  volunteer: "M12 4a3 3 0 0 1 3 3c0 1.5-1 2.5-3 4-2-1.5-3-2.5-3-4a3 3 0 0 1 3-3ZM4 15l4-1 4 1.5 4-1.5 4 1v5l-4 1-4-1.5-4 1.5-4-1Z",
  eye: "M1 12s4-7 11-7 11 7 11 7-4 7-11 7-11-7-11-7Z M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6Z",
  eyeOff: "M3 3l18 18M10.6 10.6a3 3 0 0 0 4.2 4.2M6.6 6.7C4 8.3 2 12 2 12s4 7 11 7c1.7 0 3.2-.4 4.5-1M17.9 17.9C20.4 16.1 22 12 22 12s-1.6-2.8-4.4-4.9",
  terrain: "m8 3 5 9-2 2-3-5-6 10h18L14 6l-2 4",
  water: "M2 16c2 0 2-2 4-2s2 2 4 2 2-2 4-2 2 2 4 2 2-2 4-2M2 21c2 0 2-2 4-2s2 2 4 2 2-2 4-2 2 2 4 2 2-2 4-2",
  temple: "M12 2 6 8h12L12 2ZM4 8h16M6 8v11M18 8v11M9 8v11M15 8v11M3 21h18",
  forest: "M9 4 5 11h3l-4 6h6v3h4v-3h6l-4-6h3L15 4l-2 4-1-2-1 2-2-4Z",
  bank: "M3 21h18M4 21V10M20 21V10M2 10l10-6 10 6M8 10v11M12 10v11M16 10v11",
  star: "M12 2.5l2.9 6 6.6.9-4.8 4.6 1.1 6.5L12 17.4l-5.8 3.1 1.1-6.5-4.8-4.6 6.6-.9Z",
};

export type IconName = keyof typeof paths;

export function Icon({
  name,
  size = 20,
  filled,
  className = "",
}: {
  name: IconName;
  size?: number;
  filled?: boolean;
  className?: string;
}) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill={filled ? "currentColor" : "none"}
      stroke="currentColor"
      strokeWidth="1.8"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
      className={className}
    >
      <path d={paths[name]} />
    </svg>
  );
}
