/*
  Warnings:

  - Added the required column `port` to the `ServerSession` table without a default value. This is not possible if the table is not empty.
  - Made the column `pid` on table `ServerSession` required. This step will fail if there are existing NULL values in that column.
  - Made the column `awsSessionId` on table `ServerSession` required. This step will fail if there are existing NULL values in that column.

*/
-- AlterTable
ALTER TABLE "ServerSession" ADD COLUMN     "port" INTEGER NOT NULL,
ALTER COLUMN "pid" SET NOT NULL,
ALTER COLUMN "awsSessionId" SET NOT NULL;
