"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

export default function AddCampaign() {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleMakingCampaign(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setLoading(true);
    setError(null);

    const formData = new FormData(e.currentTarget);
    const name = formData.get("name") as string;
    const description = formData.get("description") as string;

    try {
        const res = await fetch("/api/campaigns", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ name, description }),
        });

        if (!res.ok) throw new Error("Failed to create campaign");

        const campaign = await res.json();
        router.push(`/dashboard/campaigns/${campaign.id}`);
    } catch (err: any) {
        setError(err.message || "Something went wrong");
    } finally {
        setLoading(false);
    }
  }

  return (
    <div className="flex items-center justify-center min-h-screen">
        <form onSubmit={handleMakingCampaign} className="flex flex-col space-y-4 bg-grey p-4 rounded-lg shadow max-w-sm mx-auto">
        <input name="name" placeholder="Campaign Name" required />
        <textarea name="description" placeholder="Description (optional)" />
        <button type="submit" disabled={loading}>
            {loading ? "Creating..." : "Create Campaign"}
        </button>
        {error && <p className="text-red-500">{error}</p>}
        </form>
    </div>
  );
}
