# Lumo - The Real-World Browser

**Lumo** is a location-based social platform that bridges the digital and physical worlds. Users leave digital content ("loomo") at physical coordinates, which others can only discover and unlock when they are physically nearby (< 20m).

## 🚀 Key Features
- **Proximity-Based Discovery**: Content is hidden until you are physically there.
- **The Brain (Hybrid Search)**: An AI-powered ranking engine that uses local vector embeddings to match content to your "Mood" and "Identity".
- **Liquid Glass UI**: A fluid, transparent, and highly animated mobile experience.
- **Gamification**: Collect "Gold Orbs" and complete "Challenges" in the real world.

## 🏗️ Architecture
This project is a monorepo powered by [Turborepo](https://turbo.build/):
- `apps/mobile-app`: Flutter application for Android and iOS.
- `services/backend-api`: Node.js (Fastify) backend with Supabase/PostgreSQL.
- `packages/*`: Shared logic and configurations (future expansion).

## 🛠️ Tech Stack
- **Frontend**: Flutter, Riverpod, flutter_map, flutter_animate.
- **Backend**: Node.js, Fastify, Supabase, Xenova Transformers (Local AI).
=======
**Lumo** is a premium location-based social platform that bridges the digital and physical worlds. Users leave digital content ("Traces") at physical coordinates, which others can only discover and unlock when they are physically within range (< 20m).

## 💎 UX
The application features a cutting-edge **Liquid Glass** aesthetic inspired by the highest-fidelity iOS interfaces:
- **Procedural 3D Visuals**: GPU-accelerated ray-marching shaders for a fluid, tactile experience.
- **Hardware Integration**: Gyroscope-linked parallax and custom haptic signatures for every interaction.
- **Stateful Intelligence**: Context preservation across navigation branches and zero-latency local caching via Hive.

## 🚀 Key Features
- **Proximity Discovery**: Content discovery enforced by strict geofencing.
- **The Brain (AI Hybrid Search)**: Vector-based matching (384-dim) that aligns content with user "Mood" and "Identity".
- **Dynamic Feed**: Real-time memory stream powered by Supabase Broadcast Channels.
- **Hybrid Explorer**: A personalized masonry grid combining user recommendations and global content.
- **Social Graph**: Full follow/unfollow system with public activity logs.

## 🏗️ Architecture
This project is a monorepo:
- `apps/mobile-app`: High-performance Flutter application.
- `services/backend-api`: Hardened Node.js (Fastify) API with Controllers/Services pattern.
- `Database`: PostgreSQL (Supabase) with PostGIS, pgvector, and real-time triggers.

## 🛠️ Tech Stack
- **Frontend**: Flutter, Riverpod, flutter_map, flutter_animate, Hive, SensorsPlus.
- **Backend**: Node.js, Fastify, Zod, Xenova Transformers (Local AI).
>>>>>>> 7152ae6 (chore: migrate turborepo to v2 and fix workspace resolution)
- **Database**: PostgreSQL with PostGIS and pgvector.

## 🏁 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Node.js](https://nodejs.org/) (v18+)
- [Supabase Account](https://supabase.com/)

### Installation
1. Clone the repository.
2. Install dependencies:
   ```bash
   npm install
   ```
3. Setup environment variables:
   - Create `.env` files in `services/backend-api/`.

### Running Locally
- **Backend**:
  ```bash
  cd services/backend-api
  npm run dev
  ```
- **Mobile**:
  ```bash
  cd apps/mobile-app
  flutter run
  ```

## 📜 Development
<<<<<<< HEAD
- **Tests**: `npm test` from root runs tests for all packages.
- **Lint**: `npm run lint` from root.
=======
- **Tests**: `npm test` from root runs the native Node.js test runner and Flutter unit/widget tests.
- **Quality**: Strict linting and type-checking enforced across the stack.
>>>>>>> 7152ae6 (chore: migrate turborepo to v2 and fix workspace resolution)

## ⚖️ License
MIT
