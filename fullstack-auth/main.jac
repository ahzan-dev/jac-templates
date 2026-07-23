"""Composition root.

This file does two things and nothing else:

  1. Imports the server module, which registers each name from
     `services/notes.sv.jac` as a REST endpoint -- functions under
     `/function/<name>`, walkers under `/walker/<Name>`. Import the walkers
     too, not just the functions: an unimported name is not an endpoint.
     (Plain `import` here -- never `sv import`, which would mean a
     separate microservice process. And no leading dot -- the path is
     absolute or it crashes at runtime.)
  2. Loads the app-wide stylesheet into the client bundle.

Routes are not listed here -- they come from `pages/` by convention:

    pages/index.jac            ->  /          (redirects by auth state)
    pages/(public)/login.jac   ->  /login
    pages/(public)/signup.jac  ->  /signup
    pages/(auth)/dashboard.jac ->  /dashboard

The `(auth)` group name is what protects the dashboard: every page inside
it is wrapped in an AuthGuard automatically, and unauthenticated visitors
are sent to /login. There is no guard code to forget.
"""

import from services.notes {
    Note, NoteView, Profile, Stats,
    list_notes, my_profile, note_stats,
    AddNote, DeleteNote, SaveProfile, ToggleNote
}

import ".styles.global.css";

"""The shell every routed page mounts inside.

File-based routing still needs this: the client entry imports `app` from
here and hands each `pages/` match to it as `children`. Without it the
bundle fails with "does not provide an export named 'app'" and the page
renders blank.
"""
def:pub app(children: any = None) -> JsxElement {
    return <div className="min-h-svh bg-background text-foreground antialiased">
        {children}
    </div>;
}
