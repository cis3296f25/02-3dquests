interface PlayPageProps {
  params: { id: string };
}

export default async function PlayPage( { params } : PlayPageProps) {
  
  const param = await params
  const id = param.id
  return (
    <>
      <div id="game-container"></div>
      <script
        dangerouslySetInnerHTML={{
          __html: `
            window.GAME_CONFIG = {
              campaignId: "${id}",
            };
          `,
        }}
      />
      
      <iframe 
      src={`/mapmaker/3DQuestsClient.html?campaignId=${id}`}
      style={{
        position: "fixed",
        top: 0,
        left: 0,
        width: "100vw",
        height: "100vh",
        border: "none",
        margin: 0,
        padding: 0,
        overflow: "hidden",
      }}
      allowFullScreen></iframe>

    </>
  );
}
