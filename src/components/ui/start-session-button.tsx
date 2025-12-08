"use client";

import { useRouter } from "next/navigation";

export default function StartSessionButton({ campaignId }: { campaignId: string }) {
  const router = useRouter();

  async function handleStart() {
    const res = await fetch("/api/sessions/start-session", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ campaignId }),
    });

    if (!res.ok) {
      alert("Failed to start server");
      return;
    }

    router.push(`/mapmaker/index.html?campaignId=${campaignId}`);
  }

  return (
    <button
      onClick={handleStart}
      className="px-4 py-2 mt-4 rounded bg-blue-600 text-white hover:bg-blue-700"
    >
      Start Server & Play
    </button>
  );
}