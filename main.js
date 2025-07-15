const { app, BrowserWindow, ipcMain, shell } = require('electron');
const path = require('path');
const { spawn } = require('child_process');

let recorderProcess = null;

function createWindow() {
    const win = new BrowserWindow({
        width: 400,
        height: 300,
        webPreferences: {
            preload: path.join(__dirname, 'preload.js'),
        }
    });

    win.loadFile('renderer.html').catch((err) => {
        console.error("❌ Failed to load HTML:", err);
      });
    
}

app.whenReady().then(createWindow);

ipcMain.handle('start-recording', () => {
    const binaryPath = path.join(__dirname, 'record-audio');
    recorderProcess = spawn(binaryPath);

    recorderProcess.stdout.on('data', (data) => {
        console.log(`stdout: ${data}`);
    });

    recorderProcess.stderr.on('data', (data) => {
        console.error(`stderr: ${data}`);
    });

    recorderProcess.on('close', (code) => {
        console.log(`recording stopped with code ${code}`);
    });
});


ipcMain.handle('stop-recording', () => {
    if (recorderProcess) {
        recorderProcess.kill('SIGINT');
        recorderProcess = null;
    }
});

ipcMain.handle('open-folder', () => {
    const recordingsPath = path.join(app.getPath('documents'), 'SystemAudioRecordings');
    shell.openPath(recordingsPath);
});
