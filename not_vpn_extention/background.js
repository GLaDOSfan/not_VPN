// Фоновый скрипт расширения
console.log("Фоновый скрипт загружен");

// Загружаем конфигурацию из auth.js
try {
  importScripts('auth.js');
  if (typeof PROXY_CONFIG !== 'undefined' && PROXY_CONFIG) {
    console.log("auth.js загружен, прокси:", PROXY_CONFIG.host + ":" + PROXY_CONFIG.port);
  } else {
    throw new Error("PROXY_CONFIG не определен в auth.js");
  }
} catch (e) {
  console.error("Ошибка загрузки auth.js:", e);
  console.error("Расширение не будет работать без auth.js");
}

if (!PROXY_CONFIG) {
  console.error("Нет конфигурации прокси, расширение остановлено");
}

let proxyEnabled = false;

// Хранилище проблемных хостов
let problematicHosts = new Set();

// Функция получения домена второго уровня
function getSecondLevelDomain(hostname) {
  if (!hostname) return hostname;
  
  const parts = hostname.split('.');
  
  // Если меньше 2 частей, возвращаем как есть
  if (parts.length <= 2) {
    return hostname;
  }
  
  // Список двухчастных TLD (например, co.uk, com.au)
  const twoPartTlds = [
    'co.uk', 'com.au', 'co.nz', 'co.jp', 'co.za', 'com.br', 'com.mx',
    'co.il', 'com.tr', 'co.in', 'com.sg', 'com.hk', 'co.id', 'com.my',
    'co.th', 'com.vn', 'com.ua', 'co.kr', 'org.uk', 'net.uk', 'ac.uk', 'gov.uk'
  ];
  
  const lastTwo = parts.slice(-2).join('.');
  if (twoPartTlds.includes(lastTwo) && parts.length >= 3) {
    return parts.slice(-3).join('.');
  }
  
  return parts.slice(-2).join('.');
}

// Функция добавления хоста в список проблемных
function addProblematicHost(host) {
  // Получаем домен второго уровня
  const secondLevelDomain = getSecondLevelDomain(host);
  
  if (problematicHosts.has(secondLevelDomain)) {
    console.log("Хост уже в списке:", secondLevelDomain, "(из", host, ")");
    return;
  }
  
  problematicHosts.add(secondLevelDomain);
  console.log("Добавлен проблемный хост:", secondLevelDomain, "(исходный:", host, ")");
  console.log("Текущий список проблемных хостов:", Array.from(problematicHosts));
  
  // Сохраняем в storage, чтобы не терять при перезагрузке расширения
  chrome.storage.local.set({ problematicHosts: Array.from(problematicHosts) });
    if (proxyEnabled) {
    console.log("Обновляем прокси-правила с новым хостом:", secondLevelDomain);
    enableProxy();
  }
}

// Загрузка сохранённого списка при старте
chrome.storage.local.get(['problematicHosts'], (result) => {
  if (result.problematicHosts && result.problematicHosts.length > 0) {
    problematicHosts = new Set(result.problematicHosts);
    console.log("Загружены сохранённые проблемные хосты:", Array.from(problematicHosts));
  }
});

// Загружаем сохраненное состояние
chrome.storage.local.get(['proxyEnabled'], (result) => {
  proxyEnabled = result.proxyEnabled || false;
  console.log("Состояние прокси загружено:", proxyEnabled ? "включен" : "выключен");
  
  if (proxyEnabled) {
    enableProxy();
  }
});

// Включение прокси через PAC-скрипт
function enableProxy() {
  
  // Получаем актуальный список проблемных хостов
  const hostsList = Array.from(problematicHosts);
  console.log("Проксируем хосты:", hostsList);
  
  // Создаём PAC-скрипт с динамическим списком хостов
  const pacScriptContent = `function FindProxyForURL(url, host) { const proxyHosts = ${JSON.stringify(hostsList)}; for(let i = 0; i < proxyHosts.length; i++) { if(host.endsWith('.' + proxyHosts[i])) { return 'PROXY ${PROXY_CONFIG.host}:${PROXY_CONFIG.port}'; } } return 'DIRECT'; }`;
  chrome.proxy.settings.set({
    value: { 
      mode: "pac_script", 
      pacScript: { data: pacScriptContent } 
    },
    scope: "regular"
  });
}

// Отключение прокси
function disableProxy() {
  console.log("Выключаем прокси");
  
  chrome.proxy.settings.set({
    value: { mode: "direct" },
    scope: "regular"
  }, () => {
    if (chrome.runtime.lastError) {
      console.error("Ошибка выключения прокси:", chrome.runtime.lastError);
    } else {
      console.log("Прокси выключен");
    }
  });
}

// Слушатель ошибок сети
if (chrome.webRequest && chrome.webRequest.onErrorOccurred) {
  chrome.webRequest.onErrorOccurred.addListener(
    (details) => {
      const relevantErrors = [
        'net::ERR_CONNECTION_REFUSED',
        'net::ERR_TIMED_OUT',
        'net::ERR_CONNECTION_RESET',
        'net::ERR_CONNECTION_CLOSED',
        'net::ERR_NAME_NOT_RESOLVED'
      ];
      
      if (relevantErrors.includes(details.error)) {
        try {
          const url = new URL(details.url);
          const host = url.hostname;
          
          console.log("Ошибка для хоста:", host, details.error);
          
          // Добавляем проблемный хост в список
          addProblematicHost(host);
          
        } catch (e) {
          console.error("Ошибка обработки URL:", e);
        }
      }
    },
    { urls: ["<all_urls>"] }
  );
  console.log("Слушатель ошибок сети активирован");
} else {
  console.warn("chrome.webRequest.onErrorOccurred недоступен");
}

// Обработка сообщений из попапа
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  console.log("Получено сообщение:", message);
  
  if (message.action === "enableProxy") {
    proxyEnabled = true;
    chrome.storage.local.set({ proxyEnabled: true });
    enableProxy();
    sendResponse({ status: "enabled" });
  }
  
  if (message.action === "disableProxy") {
    proxyEnabled = false;
    chrome.storage.local.set({ proxyEnabled: false });
    disableProxy();
    sendResponse({ status: "disabled" });
  }
  
  if (message.action === "getProxyState") {
    sendResponse({ enabled: proxyEnabled });
  }
  
  if (message.action === "getProblematicHosts") {
    sendResponse({ hosts: Array.from(problematicHosts) });
  }
  
  return true;
});

console.log("Расширение готово");