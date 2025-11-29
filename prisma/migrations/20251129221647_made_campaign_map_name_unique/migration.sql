/*
  Warnings:

  - A unique constraint covering the columns `[campaignId,name]` on the table `maps` will be added. If there are existing duplicate values, this will fail.

*/
-- CreateIndex
CREATE UNIQUE INDEX "maps_campaignId_name_key" ON "maps"("campaignId", "name");
