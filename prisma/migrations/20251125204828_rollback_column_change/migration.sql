/*
  Warnings:

  - You are about to drop the column `sessionToken` on the `ServerSession` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE "ServerSession" DROP COLUMN "sessionToken",
ADD COLUMN     "awsSessionId" TEXT;
