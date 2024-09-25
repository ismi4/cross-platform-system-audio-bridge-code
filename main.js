const { app, BrowserWindow, ipcMain } = require('electron');
const path = require('path');
const { spawn } = require('child_process');

let mainWindow;
let recordingProcess;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 800,
    height: 600,
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false,
    },
  });

  mainWindow.loadFile('index.html');
}

app.whenReady().then(createWindow);

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) {
    createWindow();
  }
});

ipcMain.on('start-recording', (event) => {
  const executablePath = path.join(__dirname, 'audio_recorder');
  recordingProcess = spawn(executablePath);

  recordingProcess.stdout.on('data', (data) => {
    console.log(`stdout: ${data}`);
    mainWindow.webContents.send('recorder-output', data.toString());
  });

  recordingProcess.stderr.on('data', (data) => {
    console.error(`stderr: ${data}`);
    mainWindow.webContents.send('recorder-error', data.toString());
  });

  recordingProcess.on('close', (code) => {
    console.log(`child process exited with code ${code}`);
    mainWindow.webContents.send('recording-stopped', code);
  });
});

ipcMain.on('stop-recording', (event) => {
  if (recordingProcess) {
    recordingProcess.kill('SIGINT');
  } else {
    mainWindow.webContents.send('recording-stopped', 0);
  }
});