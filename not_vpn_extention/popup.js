// popup.js
let proxyEnabled = false;

// DOM элементы
const toggleProxyBtn = document.getElementById('toggleProxyBtn');
const statusTextSpan = document.getElementById('statusText');
const protectedBadge = document.getElementById('protectedBadge');
const autoAddedList = document.getElementById('autoAddedList');

// Загрузка сохраненных настроек при открытии
chrome.storage.local.get(['proxyEnabled'], (result) => {
  proxyEnabled = result.proxyEnabled || false;
  updateUI();
  loadDomainsList();
});

// Загрузка списка доменов из хранилища
function loadDomainsList() {
  chrome.storage.local.get(['proxySites'], (result) => {
    const domains = result.proxySites || [];
    updateDomainsList(domains);
  });
}

// Обновление отображения списка доменов
function updateDomainsList(domains) {
  if (!autoAddedList) return;
  
  if (!domains || domains.length === 0) {
    autoAddedList.innerHTML = '<div class="empty-list">Автоматически добавленных доменов пока нет</div>';
  } else {
    autoAddedList.innerHTML = domains.map(domain => 
      `<div class="auto-domain-item">${domain}</div>`
    ).join('');
  }
}

// Обновление интерфейса
function updateUI() {
  if (!toggleProxyBtn || !statusTextSpan) return;
  
  if (proxyEnabled) {
    toggleProxyBtn.textContent = 'ВЫКЛЮЧИТЬ ПРОКСИ';
    toggleProxyBtn.classList.remove('disabled');
    toggleProxyBtn.classList.add('enabled');
    statusTextSpan.textContent = 'Прокси включен (автоматический режим)';
    statusTextSpan.classList.remove('disconnected');
    statusTextSpan.classList.add('connected');
    if (protectedBadge) protectedBadge.style.display = 'block';
  } else {
    toggleProxyBtn.textContent = 'ВКЛЮЧИТЬ ПРОКСИ';
    toggleProxyBtn.classList.remove('enabled');
    toggleProxyBtn.classList.add('disabled');
    statusTextSpan.textContent = 'Прокси выключен';
    statusTextSpan.classList.remove('connected');
    statusTextSpan.classList.add('disconnected');
    if (protectedBadge) protectedBadge.style.display = 'none';
  }
}

// Включение прокси
function toggleProxy() {
  proxyEnabled = !proxyEnabled;
  
  if (proxyEnabled) {
    chrome.runtime.sendMessage({ action: "enableProxy" });
  } else {
    chrome.runtime.sendMessage({ action: "disableProxy" });
  }
  
  chrome.storage.local.set({ proxyEnabled: proxyEnabled });
  updateUI();
}

// Слушаем сообщения от background о добавлении доменов
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.action === "domainAutoAdded") {
    statusTextSpan.textContent = `Добавлен домен: ${message.domain} (всего: ${message.total})`;
    // Обновляем список доменов
    loadDomainsList();
    setTimeout(() => updateUI(), 2000);
  }
});

// Обработчики кнопок
if (toggleProxyBtn) toggleProxyBtn.addEventListener('click', toggleProxy);

console.log("Popup загружен");