# 3D-Quests
For TTRPG (table-top role-playing game) consumers who need to play online, 
3D-Quests is a free-to-play 3D VTT (virtual table top) web app, unlike D&D 
(Dungeons and Dragons) Beyond's Signal 3D VTT or Roll20's 2D VTT. Our product 
combines affordability, accessibility, and immersion to give the best experience 
to the largest number of people.

(Screenshot will be added later)

# How to run (for Windows)
- Have installed node v22.20.02
- Have installed npm and npx (it should come with node but just in case make sure to run npm -v and npx -v to see it installed)
- Have godot installed: 
- On the command line run the following commands:
```
npm install
```
```
npm install -g pnpm
```
```
npx prisma generate 
```
```
pnpm dev
```

To run game without signing in: 
- Go To http://localhost:3000/mapmaker/3DQuestsServer.html in your choice of browser

To run game with sign-in:
- Contact 82chaudrys@gmail.com for .env file for database credentials to sign in
- Click on http://localhost:3000/ which appears in terminal


# How to run godot server on windows powershell
```
& "C:\Path\To\Godot\Godot_v4.5.1-stable_win64_console.exe" --headless --path "godot\3d-quests" --scene "res://scenes/server.tscn"
```

# How to run (for MacOS)
Coming Soon...

# How to contribute
More to be added later... 

### How to build
More to be added later...
