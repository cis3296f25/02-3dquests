import { prisma } from "@/lib/prisma";
import { auth } from "@/lib/auth";
import { NextResponse } from "next/server";
import { headers } from "next/headers";
import crypto from "crypto";

const JWT_SECRET = process.env.JWT_SECRET

export async function GET(req: Request, { params }: { params: { campaignId: string } }) {
  const session = await auth.api.getSession({ headers: await headers() });
  if (!session) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const userId = parseInt(session.user.id);
  const { campaignId } = params;

  const isMember = await prisma.campaignMember.findFirst({ where: { campaignId, userId } });
  if (!isMember) return NextResponse.json({ error: "Forbidden" }, { status: 403 });

  const activeSession = await prisma.serverSession.findFirst({
    where: {
      campaignId,
      status: "active",
    },
    include: {
      participants: true, // optional if you want active player info
    },
  });

  
  if (!activeSession) {
    return NextResponse.json({ active: false });
  }

  return NextResponse.json({
    campaignId: activeSession.campaignId,
    session_token: activeSession.awsSessionId,
  });
}