interface PlayPageProps {
  params: { id: string };
}

export default function PlayPage( { params } : PlayPageProps) {
  return (
    <>
      <div id="game-container"></div>
      <script
        dangerouslySetInnerHTML={{
          __html: `
            window.GAME_CONFIG = {
              campaignId: "${params.id}",
            };
          `,
        }}
      />
      <script src="/godot-export/your_game.js"></script>
    </>
  );
}
