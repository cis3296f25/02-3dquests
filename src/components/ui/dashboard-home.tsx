import Link from "next/link"

export default function DashboardHome() {
    return (
        <div className="flex items-center justify-center min-h-screen">
            <div className="flex flex-col space-y-4 bg-grey p-4 rounded-lg shadow max-w-sm mx-auto">
                <Link className="" href="/dashboard/campaigns">My Campaigns</Link>
                <Link className="" href="/dashboard/settings">Settings</Link>
            </div>
        </div>
    );
}