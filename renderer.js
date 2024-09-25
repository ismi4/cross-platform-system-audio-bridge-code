const { ipcRenderer } = require('electron');

const startButton = document.getElementById('startButton');
const stopButton = document.getElementById('stopButton');
const outputDiv = document.getElementById('output');

startButton.addEventListener('click', () => {
  ipcRenderer.send('start-recording');
  console.log('Start recording button clicked');
  startButton.disabled = true;
  stopButton.disabled = false;
  outputDiv.innerHTML += '<p>Recording started...</p>';
});

stopButton.addEventListener('click', () => {
  ipcRenderer.send('stop-recording');
  console.log('Stop recording button clicked');
  startButton.disabled = false;
  stopButton.disabled = true;
  outputDiv.innerHTML += '<p>Stopping recording...</p>';
});

ipcRenderer.on('recorder-output', (event, message) => {
  console.log('Recorder output:', message);
  outputDiv.innerHTML += `<p>${message}</p>`;
});

ipcRenderer.on('recorder-error', (event, message) => {
  console.error('Recorder error:', message);
  outputDiv.innerHTML += `<p style="color: red;">Error: ${message}</p>`;
});

ipcRenderer.on('recording-stopped', (event, code) => {
  console.log('Recording stopped with code:', code);
  outputDiv.innerHTML += `<p>Recording stopped (exit code: ${code})</p>`;
  startButton.disabled = false;
  stopButton.disabled = true;
});