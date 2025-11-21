import { PrismaClient } from "@/generated/prisma";
import { withAccelerate } from "@prisma/extension-accelerate";

export const prisma = new PrismaClient({
    log: ["query", "info", "warn", "error"]
}).$extends(withAccelerate());