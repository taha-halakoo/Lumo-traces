// Hardcoded templates for MVP (Later: fetch from DB)

export interface StoryTemplate {
    id: string;
    name: string;
    backgroundStyle: 'solid' | 'gradient' | 'image';
    colors: string[]; // [primary, secondary, text]
    overlayImage?: string; // URL to the orb sticker
    fontFamily: string;
}

export class TemplateService {
    
    static getTemplates(): StoryTemplate[] {
        return [
            {
                id: 'cyberpunk_neon',
                name: 'Neon Nights',
                backgroundStyle: 'gradient',
                colors: ['#0D0D0D', '#00FF9D', '#FFFFFF'],
                overlayImage: 'https://example.com/assets/orb_green.png',
                fontFamily: 'Orbitron'
            },
            {
                id: 'retro_vhs',
                name: 'VHS Glitch',
                backgroundStyle: 'image',
                colors: ['#222222', '#FF00FF', '#FFFF00'],
                overlayImage: 'https://example.com/assets/orb_glitch.png',
                fontFamily: 'VT323'
            },
            {
                id: 'minimal_white',
                name: 'Clean Slate',
                backgroundStyle: 'solid',
                colors: ['#FFFFFF', '#000000', '#333333'],
                overlayImage: 'https://example.com/assets/orb_black.png',
                fontFamily: 'Roboto'
            }
        ];
    }

    /**
     * Logic: Suggest a template based on Trace Type or Content
     */
    static suggestTemplate(traceType: string, moodScore: number): string {
        if (traceType === 'ORB') return 'cyberpunk_neon'; // High value = Flashy
        if (moodScore > 0.8) return 'retro_vhs'; // High relevance = Cool
        return 'minimal_white'; // Standard
    }
}
