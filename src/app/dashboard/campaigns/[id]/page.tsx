import { prisma } from "@/lib/prisma";
import StartSessionButton from "@/components/ui/start-session-button";

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

      <StartSessionButton campaignId={id} />

      <h2 className="mt-4 font-semibold">Maps:</h2>
    </div>
    </div>
  );
}
