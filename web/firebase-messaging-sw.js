importScripts('https://www.gstatic.com/firebasejs/9.23.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.23.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyDI3m0A9KJggkj1JHs3ivg9QboMYQ3CzrU",
  authDomain: "fasocarbu.firebaseapp.com",
  projectId: "fasocarbu",
  storageBucket: "fasocarbu.firebasestorage.app",
  messagingSenderId: "1021658249609",
  appId: "1:1021658249609:web:2522bb302dc31166fc4958",
  measurementId: "G-G4Y5S6LSKE"
});

const messaging = firebase.messaging();
