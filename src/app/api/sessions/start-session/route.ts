import { prisma } from "@/lib/prisma";
import { auth } from "@/lib/auth";
import { NextResponse } from "next/server";
import { headers } from "next/headers"
import crypto from "crypto"

const JWT_SECRET = process.env.JWT_SECRET
const SERVER_WEBSITE = process.env.SERVER_WEBSITE

export async function POST(req: Request) {
    const session = await auth.api.getSession({headers: await headers()});
    if (!session) {
        return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const userId = parseInt(session.user.id);
    try {
        const { campaignId } = await req.json();
        if (!campaignId) {
            return NextResponse.json({ error: "Missing campaignId" }, { status: 400 })
        }
        const payload = {
            userId,
            campaignId,
            ts: Date.now()
        }

        const token = generateJWT(payload);

        const serverData = await fetch(`${SERVER_WEBSITE}/start`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "Authorization": `Bearer ${token}`
            },
            body: JSON.stringify({
                campaignId: campaignId  // <- include this
            })
        })

        const serverResponse = await serverData.json();

        const existingSession = await prisma.serverSession.findFirst({
            where: {
                campaignId,
                status: "active"
            },
        });

        if (existingSession) {
            return NextResponse.json(
                { error: "A session is already active for this campaign", session: existingSession },
                { status: 201 }
            );
        }

        const newSession = await prisma.serverSession.create({
            data: {
                campaignId,
                awsSessionId: serverResponse.awsSessionId || null,     
                activePlayers: serverResponse.activePlayers,
                createdAt: new Date(),
                status: "active", 
            },
        });

        return NextResponse.json(newSession, { status: 201 });
    } catch (error: any) {
        console.error(error);
        return NextResponse.json(
            { error: "Failed to create campaign" },
            { status: 500 }
        );
    }
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

