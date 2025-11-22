import { prisma } from "@/lib/prisma";
import Image from "next/image"

interface CampaignPageProps {
  params: { id: string }; // dynamic param from URL
}

export default async function CampaignPage({ params }: CampaignPageProps) {
  const { id } = await params;

  // Fetch campaign data from Prisma
  const campaign = await prisma.campaign.findUnique({
    where: { id },
    include: { members: true, maps: true },
  });

  if (!campaign) return <p>Campaign not found</p>;

  return (
    <div className="flex items-center min-h-screen">
    <div className="p-4">
      <h1 className="text-2xl font-bold">{campaign.name}</h1>
      <p>{campaign.description}</p>

      <h2 className="mt-4 font-semibold">Members:</h2>
      <ul>
        {campaign.members.map((m) => (
          <li key={m.id}>
            User ID: {m.userId}
          </li>
        ))}
      </ul>

      <div className="w-screen h-screen bg-black flex items-center justify-center overflow-hidden">
        <iframe
          src="/mapmaker/3DQuestsClient.html"
          className="w-[90%] h-[90%] border-2 border-gray-700 rounded-xl"
        />
      </div>
    </div>
    </div>
  );
}
