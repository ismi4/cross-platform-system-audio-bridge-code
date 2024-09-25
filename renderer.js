const { ipcRenderer } = require('electron');

document.getElementById('startButton').addEventListener('click', () => {
  ipcRenderer.send('start-recording');
  console.log('Start recording button clicked');
});