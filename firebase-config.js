// Import the functions you need from the SDKs you need
import { initializeApp } from "https://www.gstatic.com/firebasejs/10.13.0/firebase-app.js";
import { getFirestore } from "https://www.gstatic.com/firebasejs/10.13.0/firebase-firestore.js";
import { getAuth } from "https://www.gstatic.com/firebasejs/10.13.0/firebase-auth.js";

const firebaseConfig = {
  apiKey: "AIzaSyC3RaSl7970aGzdJXyJ6k7pXgdQmX0Ytl4",
  authDomain: "lifehelper-92779.firebaseapp.com",
  projectId: "lifehelper-92779",
  storageBucket: "lifehelper-92779.appspot.com",
  messagingSenderId: "990023070558",
  appId: "1:990023070558:web:7b79f6e4022201fcb615cf",
  measurementId: "G-FFQV75P1VK"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
export const db = getFirestore(app);
export const auth = getAuth(app);
