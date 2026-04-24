const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('electronAPI', {
  getSources:        ()       => ipcRenderer.invoke('get-sources'),
  setSource:         (opts)   => ipcRenderer.invoke('set-source', opts),
  setCaptureMode:    (mode)   => ipcRenderer.invoke('set-capture-mode', mode),
  stopRecording:     ()       => ipcRenderer.invoke('stop-recording'),
  checkHookAvailable:()       => ipcRenderer.invoke('check-hook-available'),
  saveFile:          (opts)   => ipcRenderer.invoke('save-file', opts),
  openFile:          (p)      => ipcRenderer.invoke('open-file', p),
  onTriggerScreenshot: (cb)   => ipcRenderer.on('trigger-screenshot', (_e, data) => cb(data)),
});
