import Link from "next/link";

import Image from 'next/image'; 

export default function Home() {
  return (
    <div className="font-sans grid grid-rows-[20px_1fr_20px] items-center justify-items-center min-h-screen p-8 pb-20 gap-16 sm:p-20">
      <main className="flex flex-col gap-[32px] row-start-2 items-center sm:items-start">
        <div className="absolute inset-y-0 left-0">
          <Image src={"/pageimg/bluednd.jpg"} width={200} height={200} alt="Blue dragon"/>
        </div>
        <div className="absolute inset-y-0 right-0">
          <Image src={"/pageimg/redngreendnd.jpg"} width={360} height={540}alt="Green dragon"/>
        </div>
        <h1 className="font-mono text-4xl">3D-Quests</h1>
      
        <div className="flex gap-4 items-center flex-col sm:flex-row">
          <Link
            href="/signup"
          >
            Sign Up
          </Link>
          <Link
            href="/login"
          >
            Login
          </Link>
        </div>
      </main>
    </div>
  );
}
