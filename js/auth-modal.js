// Google Sign-In Popup Modal & Authentication State Management

function openGoogleModal() {
  const backdrop = document.getElementById('google-modal-backdrop');
  const modalCard = document.getElementById('google-modal-card');
  if (!backdrop || !modalCard) return;

  backdrop.classList.remove('opacity-0', 'pointer-events-none');
  backdrop.classList.add('opacity-100');
  modalCard.classList.remove('scale-95', 'opacity-0');
  modalCard.classList.add('scale-100', 'opacity-100');
  document.body.style.overflow = 'hidden';
}

function closeGoogleModal() {
  const backdrop = document.getElementById('google-modal-backdrop');
  const modalCard = document.getElementById('google-modal-card');
  const customForm = document.getElementById('custom-account-form');
  const customAccBtn = document.getElementById('use-custom-account-btn');
  const loginLoading = document.getElementById('login-loading');
  if (!backdrop || !modalCard) return;

  modalCard.classList.remove('scale-100', 'opacity-100');
  modalCard.classList.add('scale-95', 'opacity-0');
  backdrop.classList.remove('opacity-100');
  backdrop.classList.add('opacity-0', 'pointer-events-none');
  document.body.style.overflow = '';

  setTimeout(() => {
    if (customForm) customForm.classList.add('hidden');
    if (customAccBtn) customAccBtn.classList.remove('hidden');
    if (loginLoading) loginLoading.classList.add('hidden');
  }, 300);
}

function simulateLogin(name, email, avatarText) {
  const loginLoading = document.getElementById('login-loading');
  const customForm = document.getElementById('custom-account-form');
  const customAccBtn = document.getElementById('use-custom-account-btn');

  if (loginLoading) loginLoading.classList.remove('hidden');
  if (customForm) customForm.classList.add('hidden');
  if (customAccBtn) customAccBtn.classList.add('hidden');

  setTimeout(() => {
    const user = { name, email, avatar: avatarText };
    localStorage.setItem('mypos_user', JSON.stringify(user));
    closeGoogleModal();
    renderAuthState();
    showToast(i18n[currentLang].login_success);
  }, 1000);
}

function renderAuthState() {
  const authContainer = document.getElementById('auth-header-container');
  if (!authContainer) return;

  const savedUser = localStorage.getItem('mypos_user');
  if (savedUser) {
    const user = JSON.parse(savedUser);
    authContainer.innerHTML = `
      <div class="flex items-center gap-2 bg-white border border-slate-200/80 rounded-full py-1 px-1.5 pr-2 sm:pr-3 shadow-xs">
        <div class="w-7 h-7 sm:w-8 sm:h-8 rounded-full bg-gradient-to-tr from-blue-600 to-indigo-600 text-white font-bold flex items-center justify-center text-[10px] sm:text-xs shadow-xs">
          ${user.avatar || 'U'}
        </div>
        <div class="hidden sm:block text-left text-xs leading-tight">
          <span class="block font-bold text-slate-800">${user.name}</span>
          <span class="block text-[10px] text-slate-500">${user.email}</span>
        </div>
        <button id="logout-btn" class="ml-0.5 sm:ml-1 text-slate-400 hover:text-rose-600 p-1 rounded-full hover:bg-slate-100 transition-colors" title="${i18n[currentLang].sign_out}">
          <span class="material-symbols-outlined text-sm sm:text-base">logout</span>
        </button>
      </div>
    `;
    const logoutBtn = document.getElementById('logout-btn');
    if (logoutBtn) {
      logoutBtn.addEventListener('click', handleLogout);
    }
  } else {
    authContainer.innerHTML = `
      <button id="nav-login-btn" class="open-login-trigger inline-flex items-center gap-1.5 sm:gap-2 bg-blue-600 hover:bg-blue-700 active:scale-95 text-white text-xs sm:text-label-lg font-semibold sm:font-label-lg px-3 sm:px-5 py-2 sm:py-2.5 rounded-full shadow-xs transition-all duration-150 ease-out">
        <span class="material-symbols-outlined text-[16px] sm:text-[18px]">account_circle</span>
        <span class="hidden sm:inline">${i18n[currentLang].nav_login}</span>
        <span class="inline sm:hidden">${i18n[currentLang].nav_login_short || 'เข้าสู่ระบบ'}</span>
      </button>
    `;
  }
}

function handleLogout() {
  localStorage.removeItem('mypos_user');
  renderAuthState();
  showToast(i18n[currentLang].logout_success);
}

// Toast notification
let toastTimer = null;
function showToast(message) {
  const toast = document.getElementById('toast-notification');
  const toastText = document.getElementById('toast-text');
  if (!toast || !toastText) return;

  if (toastTimer) clearTimeout(toastTimer);
  toastText.textContent = message;
  toast.classList.remove('translate-y-16', 'opacity-0', 'pointer-events-none');
  toast.classList.add('translate-y-0', 'opacity-100');
  toastTimer = setTimeout(() => {
    toast.classList.remove('translate-y-0', 'opacity-100');
    toast.classList.add('translate-y-16', 'opacity-0', 'pointer-events-none');
  }, 3200);
}

function initAuthModal() {
  // Delegate click for any element with class 'open-login-trigger'
  document.addEventListener('click', (e) => {
    const trigger = e.target.closest('.open-login-trigger');
    if (trigger) {
      e.preventDefault();
      openGoogleModal();
    }
  });

  const closeModalBtn = document.getElementById('close-modal-btn');
  if (closeModalBtn) {
    closeModalBtn.addEventListener('click', closeGoogleModal);
  }

  const backdrop = document.getElementById('google-modal-backdrop');
  if (backdrop) {
    backdrop.addEventListener('click', (e) => {
      if (e.target === backdrop) {
        closeGoogleModal();
      }
    });
  }

  window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      const backdrop = document.getElementById('google-modal-backdrop');
      if (backdrop && !backdrop.classList.contains('pointer-events-none')) {
        closeGoogleModal();
      }
    }
  });

  // Toggle custom account input form
  const customAccBtn = document.getElementById('use-custom-account-btn');
  const customForm = document.getElementById('custom-account-form');
  if (customAccBtn && customForm) {
    customAccBtn.addEventListener('click', () => {
      customAccBtn.classList.add('hidden');
      customForm.classList.remove('hidden');
      const input = document.getElementById('custom-email-input');
      if (input) input.focus();
    });
  }

  // Pre-configured account buttons
  document.querySelectorAll('.google-account-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      const name = btn.getAttribute('data-account-name');
      const email = btn.getAttribute('data-account-email');
      const avatar = btn.getAttribute('data-account-avatar');
      simulateLogin(name, email, avatar);
    });
  });

  // Custom email submit
  if (customForm) {
    customForm.addEventListener('submit', (e) => {
      e.preventDefault();
      const input = document.getElementById('custom-email-input');
      if (input && input.value) {
        const email = input.value;
        const name = email.split('@')[0];
        simulateLogin(name, email, name.substring(0, 2).toUpperCase());
      }
    });
  }

  // Initial Auth state rendering
  renderAuthState();
}
