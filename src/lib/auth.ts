import { betterAuth } from "better-auth";
import { prismaAdapter } from "better-auth/adapters/prisma";
import { nextCookies } from "better-auth/next-js"
import { prisma } from "@/lib/prisma"

export const auth = betterAuth({
    database: prismaAdapter(prisma, {
        provider: "postgresql", // or "mysql", "postgresql", ...etc
    }),
    emailAndPassword: { 
        enabled: true, 
    }, 
    socialProviders: { 
        google : { 
        clientId: process.env.GOOGLE_ID as string, 
        clientSecret: process.env.GOOGLE_SECRET as string, 
        }, 
    },
    plugins: [
        nextCookies()
    ],
    trustedOrigins: [
        "http://localhost:3000",
        "https://3d-quests.vercel.app",
    ],
    advanced: {
        database: {
            useNumberId: true
        }
    }
});