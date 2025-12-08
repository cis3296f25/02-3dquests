"use client"
import { useState } from "react";
import { useRouter } from "next/navigation";
import { authClient } from "@/lib/auth-client";
import Link from "next/link";

export default function SignupForm() {
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null | undefined>(null);
    const router = useRouter();

    async function handleSignup(e: React.FormEvent<HTMLFormElement>) {
        e.preventDefault();
        setLoading(true);
        setError(null);

        const formData = new FormData(e.currentTarget);

        const { data, error } = await authClient.signUp.email(
            {
                email: formData.get("email") as string,
                password: formData.get("password") as string,
                name: formData.get("name") as string,
            },
            {
                onRequest: () => setLoading(true),
                onSuccess: () => {
                    setLoading(false);
                    router.push("/dashboard");
                },
                onError: (ctx) => {
                    setLoading(false);
                    setError(ctx.error.message);
                },
            }
        );

        if (error) {
            console.error("Signup failed:", error);
            setError(error.message);
        }
    }


    return (
        <div className="flex items-center justify-center min-h-screen">
            <form onSubmit={handleSignup} className="flex flex-col text-center space-y-4 bg-grey p-4 rounded-lg shadow max-w-sm mx-auto">
                <h1>Signup</h1>
                <input name="name" placeholder="Name" className="border p-2 rounded" required />
                <input name="email" type="email" placeholder="Email" className="border p-2 rounded" required />
                <input name="password" type="password" placeholder="Password" className="border p-2 rounded" required />
                <button type="submit" className="bg-blue-500 text-white rounded p-2" disabled={loading}>
                    {loading ? "Signing up..." : "Sign Up"}
                </button>
                <Link href="/login" className="block bg-blue-500 text-white rounded p-2 text-center">Login</Link>
                {error && <p className="text-red-500">{error}</p>}
            </form>
        </div>
    );
}