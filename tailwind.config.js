/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./app/**/*.{js,jsx,ts,tsx}", "./src/**/*.{js,jsx,ts,tsx}"],
  presets: [require("nativewind/preset")],
  theme: {
    extend: {
      colors: {
        // Deep charcoal / zen-hacker palette
        ink: {
          900: "#0B0F14", // app background
          800: "#11161D", // surface
          700: "#171E27", // card
          600: "#1F2832", // raised
          500: "#2A3744", // border
        },
        neon: {
          blue: "#3DD3FF",
          purple: "#A06BFF",
          green: "#3DFF99",
          amber: "#FFC23D",
          red: "#FF5C72",
        },
        muted: "#7B8794",
      },
      fontFamily: {
        mono: ["monospace"],
      },
    },
  },
  plugins: [],
};
