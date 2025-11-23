import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma"; // your prisma client

export async function POST(req: NextRequest) {
  const { campaignId, email } = await req.json();

  if (!email) {
    return NextResponse.json({ success: false, message: "Email is required" }, { status: 400 });
  }

  // 1. Check if user exists
  const user = await prisma.user.findUnique({ where: { email } });
  if (!user) {
    return NextResponse.json({ success: false, message: "No registered user with that email" }, { status: 404 });
  }

  // 2. Check if already in campaign
  const existing = await prisma.campaignMember.findUnique({
    where: { campaignId_userId: { campaignId: campaignId, userId: user.id } },
  });

  if (existing) {
    return NextResponse.json({ success: false, message: "User already in campaign" }, { status: 409 });
  }

  // 3. Add to campaign
  await prisma.campaignMember.create({
    data: {
      campaignId: campaignId,
      userId: user.id,
      role: "PLAYER",
    },
  });

  return NextResponse.json({ success: true, message: "User added to campaign" });
}
