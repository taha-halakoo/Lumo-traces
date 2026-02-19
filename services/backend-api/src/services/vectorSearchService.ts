import { pipeline } from '@xenova/transformers';

export class VectorSearchService {
  private static embedder: any = null;
  private static modelName = 'Xenova/all-MiniLM-L6-v2';

  static async initAI() {
    if (!this.embedder) {
      console.log(`Loading local AI model (${this.modelName})...`);
      this.embedder = await pipeline('feature-extraction', this.modelName);
      console.log('AI Model loaded.');
    }
  }

  static async generateEmbedding(text: string): Promise<number[]> {
    if (!this.embedder) await this.initAI();
    const output = await this.embedder(text, { pooling: 'mean', normalize: true });
    return Array.from(output.data);
  }
}
