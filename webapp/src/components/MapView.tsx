"use client";

import { MapContainer, TileLayer, Marker, Popup } from "react-leaflet";
import L from "leaflet";
import "leaflet/dist/leaflet.css";
import Link from "next/link";
import Image from "next/image";
import { formatNpr } from "@/lib/format";
import type { Experience } from "@/lib/data/experiences";

function markerIcon(priceLabel: string) {
  return L.divIcon({
    className: "",
    html: `<div style="background:#18372D;color:#fff;padding:4px 8px;border-radius:999px;font:600 11px/1.2 var(--font-sans, sans-serif);white-space:nowrap;box-shadow:0 2px 6px rgba(1,37,28,0.3)">${priceLabel}</div>`,
    iconSize: undefined,
    iconAnchor: [20, 10],
  });
}

export function MapView({ experiences }: { experiences: Experience[] }) {
  const withCoords = experiences.filter((e) => e.lat != null && e.lng != null);
  const center: [number, number] = withCoords.length
    ? [withCoords[0].lat as number, withCoords[0].lng as number]
    : [27.7172, 85.324]; // Kathmandu fallback

  return (
    <MapContainer center={center} zoom={7} scrollWheelZoom className="h-full w-full">
      <TileLayer
        attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
      />
      {withCoords.map((e) => (
        <Marker key={e.id} position={[e.lat as number, e.lng as number]} icon={markerIcon(formatNpr(e.price_paisa))}>
          <Popup>
            <div className="w-48">
              <div className="relative mb-2 aspect-[4/3] w-full overflow-hidden rounded">
                <Image src={e.cover_image_url} alt={e.title} fill className="object-cover" sizes="192px" />
              </div>
              <p className="text-sm font-semibold leading-snug">{e.title}</p>
              <p className="text-xs text-neutral-500">{e.location_name}</p>
              <p className="mt-1 text-sm font-semibold text-[#18372D]">{formatNpr(e.price_paisa)}</p>
              <Link href={`/experience/${e.slug}`} className="mt-1 block text-xs font-semibold text-[#18372D] underline">
                View Experience
              </Link>
            </div>
          </Popup>
        </Marker>
      ))}
    </MapContainer>
  );
}
