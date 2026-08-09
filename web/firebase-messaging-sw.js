// Service worker de Firebase Cloud Messaging para la versión web de
// FutLiga — necesario para recibir notificaciones push con el
// navegador cerrado o en segundo plano.
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyDhvodzRm-t8iWbTsqAXs0Gq2srkErJBas",
  authDomain: "futliga-1a796.firebaseapp.com",
  projectId: "futliga-1a796",
  storageBucket: "futliga-1a796.firebasestorage.app",
  messagingSenderId: "371860469223",
  appId: "1:371860469223:web:cc19def30a5d1810917942",
  measurementId: "G-F846LYGJJW"
});

const messaging = firebase.messaging();
