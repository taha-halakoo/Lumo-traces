// Using Nominatim (OSM) for free Geocoding
// TERMS OF USE: Max 1 request per second. User-Agent is mandatory.

const NOMINATIM_ENDPOINT = 'https://nominatim.openstreetmap.org/reverse';

export async function reverseGeocode(lat: number, long: number): Promise<string | null> {
  try {
    const url = `${NOMINATIM_ENDPOINT}?format=json&lat=${lat}&lon=${long}`;
    
    const response = await fetch(url, {
      headers: {
        'User-Agent': 'TracesApp/1.0 (contact@traces.app)' // Required by OSM policy
      }
    });

    if (!response.ok) return null;

    const data = await response.json();
    
    // Return formatted address or display_name
    return data.display_name || null;
  } catch (error) {
    console.error('Geocoding error:', error);
    return null;
  }
}
