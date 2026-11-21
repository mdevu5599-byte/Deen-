import {FirebaseApp, getApps, initializeApp} from 'firebase/app';
import {Auth, getAuth} from 'firebase/auth';
import {Firestore, getFirestore} from 'firebase/firestore';
import {Functions, getFunctions, httpsCallable} from 'firebase/functions';

const cfg = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID,
};

export const isConfigured = Boolean(cfg.apiKey && cfg.projectId && cfg.appId);

let app: FirebaseApp | undefined;
function getApp(): FirebaseApp {
  if (!app) app = getApps()[0] ?? initializeApp(cfg);
  return app;
}
export const auth = (): Auth => getAuth(getApp());
export const db = (): Firestore => getFirestore(getApp());
export const functions = (): Functions => getFunctions(getApp());

/** Calls a callable Cloud Function. Role checks happen server-side in the function. */
export async function call<T = any>(name: string, data: unknown): Promise<T> {
  const res = await httpsCallable(functions(), name)(data);
  return res.data as T;
}
