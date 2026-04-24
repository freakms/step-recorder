const { app, BrowserWindow, ipcMain, desktopCapturer, globalShortcut, screen, dialog, shell } = require('electron');
const path = require('path');
const fs = require('fs');
const os = require('os');

let mainWindow = null;
let overlayWindow = null;
let isRecording = false;
let selectedSourceId = null;
let captureMode = 'manual'; // 'manual' | 'click' | 'click-smart'
let uiohook = null;
let lastClickTime = 0;
const clickCooldownMs = 600;

function loadUiohook() {
  try {
    const { uIOhook } = require('uiohook-napi');
    return uIOhook;
  } catch (e) {
    console.warn('uiohook-napi not available:', e.message);
    return null;
  }
}

function createMainWindow() {
  mainWindow = new BrowserWindow({
    width: 1100,
    height: 780,
    minWidth: 800,
    minHeight: 600,
    title: 'Step Recorder',
    backgroundColor: '#f7f7f5',
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
    },
  });
  mainWindow.loadFile(path.join(__dirname, 'index.html'));
  mainWindow.on('closed', () => { mainWindow = null; });
}

function createOverlay() {
  if (overlayWindow) { overlayWindow.close(); overlayWindow = null; }
  const { width, height } = screen.getPrimaryDisplay().workAreaSize;
  overlayWindow = new BrowserWindow({
    width, height, x: 0, y: 0,
    transparent: true, frame: false,
    alwaysOnTop: true, skipTaskbar: true,
    focusable: false, hasShadow: false,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true, nodeIntegration: false,
    }
  });
  overlayWindow.setIgnoreMouseEvents(true);
  overlayWindow.loadFile(path.join(__dirname, 'overlay.html'));
  overlayWindow.setAlwaysOnTop(true, 'screen-saver');
}

function startMouseHook() {
  if (!uiohook) uiohook = loadUiohook();
  if (!uiohook) return false;

  // Remove any existing listeners first
  try { uiohook.removeAllListeners('mousedown'); } catch(e) {}

  uiohook.on('mousedown', (e) => {
    if (!isRecording) return;
    if (captureMode !== 'click' && captureMode !== 'click-smart') return;

    const now = Date.now();
    if (now - lastClickTime < clickCooldownMs) return;
    lastClickTime = now;

    // click-smart: skip clicks on the Step Recorder window itself
    if (captureMode === 'click-smart' && mainWindow) {
      const bounds = mainWindow.getBounds();
      if (e.x >= bounds.x && e.x <= bounds.x + bounds.width &&
          e.y >= bounds.y && e.y <= bounds.y + bounds.height) {
        return;
      }
    }

    // Delay so UI updates before screenshot
    setTimeout(() => {
      if (mainWindow) mainWindow.webContents.send('trigger-screenshot', { label: null, auto: true });
    }, 220);
  });

  try {
    uiohook.start();
    return true;
  } catch(e) {
    console.warn('uiohook start failed:', e.message);
    return false;
  }
}

function stopMouseHook() {
  if (!uiohook) return;
  try {
    uiohook.removeAllListeners('mousedown');
    uiohook.stop();
    uiohook = null;
  } catch(e) {}
}

app.whenReady().then(() => {
  createMainWindow();

  globalShortcut.register('F9', () => {
    if (isRecording && mainWindow) {
      mainWindow.webContents.send('trigger-screenshot', { label: null, auto: false });
    }
  });

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createMainWindow();
  });
});

app.on('will-quit', () => {
  globalShortcut.unregisterAll();
  stopMouseHook();
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});

// ─── IPC ──────────────────────────────────────────────────────────
ipcMain.handle('get-sources', async () => {
  const sources = await desktopCapturer.getSources({
    types: ['window', 'screen'],
    thumbnailSize: { width: 320, height: 180 },
    fetchWindowIcons: true,
  });
  return sources.map(s => ({
    id: s.id,
    name: s.name,
    thumbnail: s.thumbnail.toDataURL(),
    appIcon: s.appIcon ? s.appIcon.toDataURL() : null,
  }));
});

ipcMain.handle('set-source', (event, { sourceId, mode }) => {
  selectedSourceId = sourceId;
  captureMode = mode || 'manual';
  isRecording = true;
  createOverlay();

  if (captureMode === 'click' || captureMode === 'click-smart') {
    const hookOk = startMouseHook();
    return { ok: true, hookAvailable: hookOk };
  }
  return { ok: true, hookAvailable: true };
});

ipcMain.handle('set-capture-mode', (event, mode) => {
  const prev = captureMode;
  captureMode = mode;
  if (isRecording) {
    if (mode === 'click' || mode === 'click-smart') {
      startMouseHook();
    } else if (prev !== 'manual') {
      stopMouseHook();
    }
  }
  return { ok: true };
});

ipcMain.handle('stop-recording', () => {
  isRecording = false;
  selectedSourceId = null;
  stopMouseHook();
  if (overlayWindow) { overlayWindow.close(); overlayWindow = null; }
  return { ok: true };
});

ipcMain.handle('check-hook-available', () => {
  const h = loadUiohook();
  return { available: !!h };
});

ipcMain.handle('save-file', async (event, { defaultName, content, filters }) => {
  const result = await dialog.showSaveDialog(mainWindow, {
    defaultPath: path.join(os.homedir(), 'Desktop', defaultName),
    filters: filters || [{ name: 'All Files', extensions: ['*'] }],
  });
  if (result.canceled || !result.filePath) return { ok: false };
  fs.writeFileSync(result.filePath, content, 'utf8');
  return { ok: true, filePath: result.filePath };
});

ipcMain.handle('open-file', (event, filePath) => {
  shell.openPath(filePath);
});
