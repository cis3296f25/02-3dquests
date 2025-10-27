"use client"
import { authClient } from "@/lib/auth-client"
import { useRouter } from "next/navigation"

export default function SettingsHome() {
    const router = useRouter();

    async function signout() {
        
        const data = await authClient.signOut({
            fetchOptions: {
                onSuccess: () => {
                router.push("/login"); // redirect to login page
                },
            },
        });
    }
    return (
        <div className="flex items-center justify-center min-h-screen">
            <div className="flex flex-col space-y-4 bg-grey p-4 rounded-lg shadow max-w-sm mx-auto">
                <button className="onhover:bg-black"onClick={signout}>Signout</button>
            </div>
        </div>
    );
}