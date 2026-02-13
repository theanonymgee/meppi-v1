// Tailwind CSS Configuration for MEPPI Dashboard
// Editorial Financial Times Style Design System

export default {
  content: [
    './app/views/**/*.html.erb',
    './app/javascript/**/*.{js,ts}',
    './app/assets/stylesheets/**/*.css'
  ],
  theme: {
    extend: {
      colors: {
        // Primary Colors - Newsprint theme
        'bg-primary': '#FDFBF7',
        'bg-secondary': '#F5F2EA',
        'bg-tertiary': '#EAE8DF',

        // Text Colors
        'text-primary': '#1A1A1A',
        'text-secondary': '#5A5A5A',
        'text-tertiary': '#8A8A8A',
        'text-inverse': '#FFFFFF',

        // Accent Colors - Financial Times palette
        'accent-blue': '#1E50A2',
        'accent-blue-light': '#4A7BC4',
        'accent-red': '#D74850',
        'accent-green': '#2E7D32',
        'accent-amber': '#F59E0B',
        'accent-purple': '#7C3AED',

        // Border & Divider
        'border-color': '#E0DCC8',
        'divider': '#D4D0C8'
      },
      fontFamily: {
        display: ['Playfair Display', 'Georgia', 'Times New Roman', 'serif'],
        body: ['Source Sans Pro', '-apple-system', 'BlinkMacSystemFont', 'sans-serif'],
        mono: ['IBM Plex Mono', 'SF Mono', 'Monaco', 'monospace']
      },
      fontSize: {
        'xs': '0.640rem',    // 10.24px
        'sm': '0.800rem',    // 12.8px
        'base': '1.000rem',  // 16px
        'lg': '1.250rem',    // 20px
        'xl': '1.563rem',    // 25px
        '2xl': '1.953rem',   // 31.25px
        '3xl': '2.441rem',   // 39.06px
        '4xl': '3.052rem'    // 48.83px
      },
      spacing: {
        '1': '0.250rem',  // 4px
        '2': '0.500rem',  // 8px
        '3': '0.750rem',  // 12px
        '4': '1.000rem',  // 16px
        '5': '1.250rem',  // 20px
        '6': '1.500rem',  // 24px
        '8': '2.000rem',  // 32px
        '10': '2.500rem', // 40px
        '12': '3.000rem', // 48px
        '16': '4.000rem'  // 64px
      },
      boxShadow: {
        'card': '0 1px 3px rgba(0, 0, 0, 0.08)',
        'card-hover': '0 4px 12px rgba(0, 0, 0, 0.12)'
      }
    }
  },
  plugins: []
}
