import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    host: '0.0.0.0',
    port: 5173,
    allowedHosts: [
      'www.serenespaceai.com', // ✅ your domain
      'serenespaceai.com',     // (optional, non-www version)
      'localhost',             // for local dev
      '127.0.0.1'              // for IP access
    ],
  },
})

