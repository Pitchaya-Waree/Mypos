// Tailwind CSS Custom Theme Configuration
tailwind.config = {
  darkMode: "class",
  theme: {
    extend: {
      colors: {
        "primary": "#00288e",
        "primary-container": "#1e40af",
        "on-primary": "#ffffff",
        "on-primary-container": "#ffffff",
        "primary-fixed": "#dde1ff",
        "primary-fixed-dim": "#b8c4ff",
        "on-primary-fixed": "#001453",
        "secondary": "#006591",
        "secondary-container": "#39b8fd",
        "on-secondary": "#ffffff",
        "tertiary": "#005236",
        "tertiary-container": "#00563a",
        "surface": "#faf8ff",
        "surface-bright": "#faf8ff",
        "surface-dim": "#d2d9f4",
        "surface-container": "#eaedff",
        "surface-container-low": "#f2f3ff",
        "surface-container-high": "#e2e7ff",
        "surface-container-highest": "#dae2fd",
        "surface-container-lowest": "#ffffff",
        "on-surface": "#131b2e",
        "on-surface-variant": "#444653",
        "outline": "#757684",
        "outline-variant": "#c4c5d5",
        "background": "#faf8ff",
        "on-background": "#131b2e",
        "canvas-mint": "#f4f7fc",
        "surface-ice": "#eff6ff",
        "coral-subtle": "#eff6ff",
        "teal-dark": "#1d4ed8"
      },
      borderRadius: {
        "DEFAULT": "1rem",
        "lg": "2rem",
        "xl": "3rem",
        "full": "9999px"
      },
      spacing: {
        "space-lg": "1.5rem",
        "space-2xs": "0.25rem",
        "gutter": "1.25rem",
        "gutter-mobile": "0.75rem",
        "space-xs": "0.5rem",
        "space-sm": "0.75rem",
        "margin-mobile": "1rem",
        "space-xl": "2rem",
        "space-md": "1rem",
        "margin": "2rem",
        "space-2xl": "3rem"
      },
      fontFamily: {
        "headline-md": ["Plus Jakarta Sans", "Prompt", "sans-serif"],
        "title-md": ["Plus Jakarta Sans", "Prompt", "sans-serif"],
        "headline-lg-mobile": ["Plus Jakarta Sans", "Prompt", "sans-serif"],
        "body-lg": ["Plus Jakarta Sans", "Prompt", "sans-serif"],
        "display-hero-mobile": ["Plus Jakarta Sans", "Prompt", "sans-serif"],
        "display-hero": ["Plus Jakarta Sans", "Prompt", "sans-serif"],
        "label-md": ["Plus Jakarta Sans", "Prompt", "sans-serif"],
        "body-md": ["Plus Jakarta Sans", "Prompt", "sans-serif"],
        "label-sm": ["Plus Jakarta Sans", "Prompt", "sans-serif"],
        "body-sm": ["Plus Jakarta Sans", "Prompt", "sans-serif"],
        "headline-lg": ["Plus Jakarta Sans", "Prompt", "sans-serif"],
        "label-lg": ["Plus Jakarta Sans", "Prompt", "sans-serif"]
      },
      fontSize: {
        "headline-md": ["22px", { "lineHeight": "30px", "letterSpacing": "-0.01em", "fontWeight": "600" }],
        "title-md": ["18px", { "lineHeight": "26px", "fontWeight": "600" }],
        "headline-lg-mobile": ["24px", { "lineHeight": "32px", "letterSpacing": "-0.01em", "fontWeight": "700" }],
        "body-lg": ["16px", { "lineHeight": "26px", "fontWeight": "400" }],
        "display-hero-mobile": ["32px", { "lineHeight": "40px", "letterSpacing": "-0.02em", "fontWeight": "800" }],
        "display-hero": ["48px", { "lineHeight": "58px", "letterSpacing": "-0.03em", "fontWeight": "800" }],
        "label-md": ["12px", { "lineHeight": "16px", "fontWeight": "600" }],
        "body-md": ["14px", { "lineHeight": "22px", "fontWeight": "400" }],
        "label-sm": ["10px", { "lineHeight": "14px", "letterSpacing": "0.04em", "fontWeight": "700" }],
        "body-sm": ["12px", { "lineHeight": "18px", "fontWeight": "400" }],
        "headline-lg": ["32px", { "lineHeight": "40px", "letterSpacing": "-0.02em", "fontWeight": "700" }],
        "label-lg": ["14px", { "lineHeight": "20px", "fontWeight": "600" }]
      }
    }
  }
};
