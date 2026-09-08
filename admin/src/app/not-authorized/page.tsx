import Link from "next/link";

// The only thing a non-staff (or under-scoped) signed-in account sees. Nothing
// else renders.
export default function NotAuthorizedPage() {
  return (
    <div className="flex min-h-full items-center justify-center px-6">
      <div className="max-w-md text-center">
        <h1 className="text-xl font-bold text-[var(--color-forest)]">Not authorized</h1>
        <p className="mt-3 text-sm text-[var(--color-ink)]/70">
          This account is signed in but is not an active staff member with the
          required access. If that is unexpected, ask a founder to add you under
          Staff.
        </p>
        <form action="/auth/signout" method="post" className="mt-6">
          <button className="text-sm font-medium text-[var(--color-error)] hover:underline" type="submit">
            Sign out
          </button>
        </form>
        <Link href="/login" className="mt-2 block text-xs text-[var(--color-ink)]/50 hover:underline">
          Back to sign in
        </Link>
      </div>
    </div>
  );
}
