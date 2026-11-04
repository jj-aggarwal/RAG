import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// Proxies /api/* to the Flask backend during development, so the frontend
// can just call fetch('/api/ask') without worrying about CORS or the
// backend's actual port.
export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      '/api': {
        target: 'http://localhost:5000',
        changeOrigin: true,
      },
    },
  },
})
