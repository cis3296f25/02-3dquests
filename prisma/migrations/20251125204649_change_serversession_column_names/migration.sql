/*
  Warnings:

  - You are about to drop the column `awsSessionId` on the `ServerSession` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE "ServerSession" DROP COLUMN "awsSessionId",
ADD COLUMN     "sessionToken" TEXT;
