interface ParasiticState {
    traceId: string;
    carrierUserId: string;
    infectionLat: number;
    infectionLong: number;
    cureDistanceKm: number; // e.g., 1.0 km
    status: 'INFECTED' | 'CURED';
}

// Haversine implementation for logic completeness
function calcDist(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const R = 6371; // Radius of the earth in km
    const dLat = (lat2 - lat1) * (Math.PI / 180);
    const dLon = (lon2 - lon1) * (Math.PI / 180);
    const a = 
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(lat1 * (Math.PI / 180)) * Math.cos(lat2 * (Math.PI / 180)) * 
      Math.sin(dLon / 2) * Math.sin(dLon / 2); 
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a)); 
    const d = R * c; 
    return d;
}

export class ParasiteService {
    
    /**
     * Checks if the carrier has moved far enough to "Cure" the parasite (and drop it).
     */
    static checkCureCondition(state: ParasiticState, currentLat: number, currentLong: number): boolean {
        if (state.status === 'CURED') return true;

        const distanceMoved = calcDist(state.infectionLat, state.infectionLong, currentLat, currentLong);
        
        if (distanceMoved >= state.cureDistanceKm) {
            return true; // You walked 1km! You can now drop the trace.
        }
        
        return false;
    }

    /**
     * "Infects" a user with a trace.
     */
    static infectUser(userId: string, traceId: string, lat: number, long: number): ParasiticState {
        return {
            traceId,
            carrierUserId: userId,
            infectionLat: lat,
            infectionLong: long,
            cureDistanceKm: 1.0, // Hardcoded difficulty for MVP
            status: 'INFECTED'
        };
    }
}
