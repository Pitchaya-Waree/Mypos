// Language Switching Engine
let currentLang = localStorage.getItem('mypos_lang') || 'th';

function applyLanguage(lang) {
  currentLang = lang;
  localStorage.setItem('mypos_lang', lang);
  document.documentElement.lang = lang;

  // Update document title
  if (i18n[lang] && i18n[lang].page_title) {
    document.title = i18n[lang].page_title;
  }

  // Update elements with data-i18n (plain text)
  document.querySelectorAll('[data-i18n]').forEach(el => {
    const key = el.getAttribute('data-i18n');
    if (i18n[lang] && i18n[lang][key]) {
      el.textContent = i18n[lang][key];
    }
  });

  // Update elements with data-i18n-html (rich markup)
  document.querySelectorAll('[data-i18n-html]').forEach(el => {
    const key = el.getAttribute('data-i18n-html');
    if (i18n[lang] && i18n[lang][key]) {
      el.innerHTML = i18n[lang][key];
    }
  });

  // Update Language Button Active Styles
  const btnTh = document.getElementById('lang-btn-th');
  const btnEn = document.getElementById('lang-btn-en');
  if (btnTh && btnEn) {
    if (lang === 'th') {
      btnTh.className = "px-2.5 py-1 rounded-full bg-blue-600 text-white font-semibold shadow-xs transition-all";
      btnEn.className = "px-2.5 py-1 rounded-full text-on-surface-variant hover:text-blue-600 transition-colors";
    } else {
      btnEn.className = "px-2.5 py-1 rounded-full bg-blue-600 text-white font-semibold shadow-xs transition-all";
      btnTh.className = "px-2.5 py-1 rounded-full text-on-surface-variant hover:text-blue-600 transition-colors";
    }
  }

  // Refresh auth state view in current language
  if (typeof renderAuthState === 'function') {
    renderAuthState();
  }
}

function initI18n() {
  const btnTh = document.getElementById('lang-btn-th');
  const btnEn = document.getElementById('lang-btn-en');
  if (btnTh) {
    btnTh.addEventListener('click', () => applyLanguage('th'));
  }
  if (btnEn) {
    btnEn.addEventListener('click', () => applyLanguage('en'));
  }

  // Apply default or stored language
  applyLanguage(currentLang);
}
