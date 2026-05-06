/**
 * src/main/dataStore.js
 * Data persistence manager using electron-store
 */

const Store = require('electron-store');

const defaultConfig = {
  appCustomizations: {},
  preferences: {
    viewMode: 'default',
    sortBy: 'name',
    activeCategory: 'all',
    autoStart: false,
    minimizeToTray: true,
  },
  usageStats: {},
  customCategories: [],
};

let store;

function init() {
  store = new Store({
    name: 'mac-doker-data',
    defaults: defaultConfig,
  });
}

function get(key, defaultValue = undefined) {
  return store.get(key, defaultValue);
}

function set(key, value) {
  store.set(key, value);
}

function remove(key) {
  store.delete(key);
}

function incrementUsage(appName) {
  const stats = store.get('usageStats', {});
  const now = Date.now();

  if (!stats[appName]) {
    stats[appName] = { count: 0, lastUsed: 0, history: [] };
  }

  stats[appName].count += 1;
  stats[appName].lastUsed = now;
  stats[appName].history.unshift({ timestamp: now, action: 'launch' });

  if (stats[appName].history.length > 30) {
    stats[appName].history = stats[appName].history.slice(0, 30);
  }

  store.set('usageStats', stats);
}

module.exports = { init, get, set, remove, incrementUsage };
