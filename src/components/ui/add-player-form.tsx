"use client";

import { useState } from "react";

interface AddPlayerFormProps {
  campaignId: string;
}

export default function AddPlayerForm({ campaignId }: AddPlayerFormProps) {
  const [email, setEmail] = useState("");
  const [status, setStatus] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setStatus("Adding...");

    try {
      const res = await fetch(`/api/campaign/add-player`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, campaignId }),
      });

      const data = await res.json();
      if (data.success) {
        setStatus(data.message);
        setEmail("");
      } else {
        setStatus(data.message);
      }
    } catch (err) {
      console.error(err);
      setStatus("Error adding user");
    }
  };

  return (
    <form onSubmit={handleSubmit} className="flex flex-col gap-2 w-full max-w-md">
      <input
        type="email"
        placeholder="Enter user email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        className="border p-2 rounded"
        required
      />
      <button type="submit" className="bg-blue-500 text-white p-2 rounded">
        Add Player
      </button>
      {status && <p>{status}</p>}
    </form>
  );
}
