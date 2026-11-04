import L from 'leaflet'
import 'leaflet/dist/leaflet.css'
import markerIcon from 'leaflet/dist/images/marker-icon.png'
import markerIcon2x from 'leaflet/dist/images/marker-icon-2x.png'
import markerShadow from 'leaflet/dist/images/marker-shadow.png'
import { LocateFixed } from 'lucide-react'
import { useEffect, useState } from 'react'
import { MapContainer, Marker, TileLayer, useMap, useMapEvents } from 'react-leaflet'

import { Button } from '@/components/ui/button'

export type GeoPoint = { lat: number; lng: number }

const DUSHANBE: GeoPoint = { lat: 38.5598, lng: 68.787 }

const pin = L.icon({
  iconUrl: markerIcon,
  iconRetinaUrl: markerIcon2x,
  shadowUrl: markerShadow,
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  shadowSize: [41, 41],
})

function ClickHandler({ onPick }: { onPick: (point: GeoPoint) => void }) {
  useMapEvents({
    click: (e) => onPick({ lat: e.latlng.lat, lng: e.latlng.lng }),
  })

  return null
}

function ResizeFix() {
  const map = useMap()

  useEffect(() => {
    const timer = setTimeout(() => map.invalidateSize(), 300)

    return () => clearTimeout(timer)
  }, [map])

  return null
}

export function LocationPicker({
  value,
  onChange,
}: {
  value: GeoPoint | null
  onChange: (point: GeoPoint) => void
}) {
  const [map, setMap] = useState<L.Map | null>(null)
  const [geoError, setGeoError] = useState<string | null>(null)

  const locate = () => {
    setGeoError(null)

    if (!navigator.geolocation) {
      return setGeoError('Браузер не поддерживает геолокацию.')
    }

    navigator.geolocation.getCurrentPosition(
      (position) => {
        const point = { lat: position.coords.latitude, lng: position.coords.longitude }

        onChange(point)
        map?.setView([point.lat, point.lng], 17)
      },
      () => setGeoError('Не удалось определить местоположение.'),
      { enableHighAccuracy: true, timeout: 10000 },
    )
  }

  const center = value ?? DUSHANBE

  return (
    <div>
      <div className="isolate overflow-hidden rounded-xl border">
        <MapContainer
          ref={setMap}
          center={[center.lat, center.lng]}
          zoom={value ? 17 : 12}
          scrollWheelZoom
          className="h-64 w-full"
        >
          <TileLayer
            url="https://tile.openstreetmap.org/{z}/{x}/{y}.png"
            attribution="&copy; OpenStreetMap contributors"
          />
          <ClickHandler onPick={onChange} />
          <ResizeFix />
          {value && <Marker position={[value.lat, value.lng]} icon={pin} />}
        </MapContainer>
      </div>

      <div className="mt-2 flex flex-wrap items-center gap-3">
        <Button type="button" variant="outline" size="sm" onClick={locate}>
          <LocateFixed className="size-4" />
          Моё местоположение
        </Button>
        <p className="text-sm text-stone-500">
          {value
            ? `${value.lat.toFixed(5)}, ${value.lng.toFixed(5)}`
            : 'Нажмите на карту, чтобы поставить точку'}
        </p>
      </div>

      {geoError && <p className="mt-2 text-sm text-red-600">{geoError}</p>}
    </div>
  )
}