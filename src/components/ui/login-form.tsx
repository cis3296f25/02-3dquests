"use client"
import { useState } from "react";
import { useRouter } from "next/navigation";
import { authClient } from "@/lib/auth-client";
import Link from "next/link"

export default function SignupForm() {
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null | undefined>(null);
    const router = useRouter();

    async function handleLogin(e: React.FormEvent<HTMLFormElement>) {
        e.preventDefault();
        setLoading(true);
        setError(null);

        const formData = new FormData(e.currentTarget);
        const email = formData.get("email") as string;
        const password = formData.get("password") as string;

        const { data, error } = await authClient.signIn.email(
            {
                email,
                password,
            },
            {
                onRequest: () => setLoading(true),
                onSuccess: () => {
                    setLoading(false);
                    router.push("/dashboard"); // or "/login"
                },
                onError: (ctx) => {
                    setLoading(false);
                    setError(ctx.error.message);
                },
            }
        );

        // You can still handle the final result if needed
        if (error) {
            console.error("Signup failed:", error);
            setError(error.message);
        }
    }


    return (
        <div className="flex items-center justify-center min-h-screen">
            <form onSubmit={handleLogin} className="flex flex-col space-y-4 bg-grey p-4 rounded-lg shadow max-w-sm mx-auto">
                <input name="email" type="email" placeholder="Email" className="border p-2 rounded" required />
                <input name="password" type="password" placeholder="Password" className="border p-2 rounded" required />
                <button type="submit" className="bg-blue-500 text-white rounded p-2" disabled={loading}>
                    {loading ? "Logging In..." : "Login"}
                </button>
                <Link href="/signup" className="block bg-blue-500 text-white rounded p-2 text-center">Signup</Link>
                {error && <p className="text-red-500">{error}</p>}
            </form>
        </div>
    );
}