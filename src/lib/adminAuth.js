import { onAuthStateChanged } from "firebase/auth";
import { auth } from "./firebase.js";

function getCurrentUser() {
    return new Promise((resolve) => {
        const unsubscribe = onAuthStateChanged(auth, (user) => {
            unsubscribe();
            resolve(user);
        });
    });
}

export async function requireAdminSession() {
    const user = await getCurrentUser();

    if (!user) {
        window.location.href = "/admin/login";
        return null;
    }

    return user;
}
