import { prisma } from "@/lib/prisma";
import { auth } from "@/lib/auth";
import { NextRequest, NextResponse } from "next/server";
import { headers } from "next/headers";
import crypto from "crypto";

const JWT_SECRET = process.env.JWT_SECRET

export const dynamic = "force-dynamic";


export async function GET(req: NextRequest, context: { params: { campaignId: string } }) {
  const session = await auth.api.getSession({ headers: await headers() });
  if (!session) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const userId = parseInt(session.user.id);
  const { campaignId } = context.params;

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
  const payload = {
      userId,
      ts: Date.now()
  }

  const user_jwt = generateJWT(payload);

  const response =  NextResponse.json({
    campaignId: activeSession.campaignId,
    session_token: activeSession.awsSessionId,
    user_jwt
  });
  
  return response
}

function generateJWT(payload: object) {
    if (!JWT_SECRET) {
        throw new Error("JWT_SECRET is not defined")
    }
    const header = { alg: "HS256", typ: "JWT" }

    const base64url = (obj: object) =>
        Buffer.from(JSON.stringify(obj)).toString("base64url")

    const unsignedToken = `${base64url(header)}.${base64url(payload)}`

    const signature = crypto
        .createHmac("sha256", JWT_SECRET)
        .update(unsignedToken)
        .digest("base64url")

    return `${unsignedToken}.${signature}`
}

