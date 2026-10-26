// Main Application Bootstrapper & Dynamic Component Loader

async function loadComponents() {
  const placeholders = document.querySelectorAll('[data-component]');
  
  // Fetch and replace all component placeholders concurrently
  await Promise.all(Array.from(placeholders).map(async (placeholder) => {
    const file = placeholder.getAttribute('data-component');
    try {
      const res = await fetch(file);
      if (!res.ok) throw new Error(`HTTP ${res.status} when fetching ${file}`);
      const html = await res.text();
      
      // Replace placeholder with loaded HTML markup
      placeholder.outerHTML = html;
    } catch (err) {
      console.error(`Error loading component [${file}]:`, err);
      placeholder.innerHTML = `<div class="p-4 text-rose-500 text-sm">Failed to load ${file}</div>`;
    }
  }));
}

// Initialize Application once DOM is ready
document.addEventListener('DOMContentLoaded', async () => {
  // 1. Load HTML modular components
  await loadComponents();

  // 2. Initialize Language Engine
  if (typeof initI18n === 'function') {
    initI18n();
  }

  // 3. Initialize Google Auth Modal & Events
  if (typeof initAuthModal === 'function') {
    initAuthModal();
  }
});
