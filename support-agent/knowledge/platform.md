# The platform

The platform is a browser-based workspace for building, previewing, and shipping
web applications. You write code in the editor, watch it run in a live preview,
and deploy it to a public URL when it is ready.

This file is the agent's knowledge base. It is read from disk at runtime, so
editing this text changes what the agent knows on the next question — no code
change, no restart of your thinking, no retraining.

## Projects

A project is one application: its source files, its git history, and its
settings. Every project is independent — its own files, its own preview, its own
deployment.

Projects are created from a template, from scratch, by cloning something from
the community gallery, or by importing an existing repository.

Each plan allows a fixed number of projects at once. When you are at your
project limit, creating another one fails until you delete an old project or
move to a higher plan. Deleting a project frees its slot immediately.

## Previews

A preview is your project running live, in a sandbox, while you edit it. It
rebuilds as you type, so it always reflects the code currently in the editor.

A preview is **not** a deployment. It is temporary and tied to your editing
session: it sleeps when you stop working and starts again when you come back.
The URL is not stable and it is not meant for real users or real traffic.

Previews are available on every plan, including the free plan.

## Preview sharing

A shared preview is a preview with a link other people can open. It is the way
to show work in progress to a teammate or a client without deploying it.

A shared preview is still a preview: it sleeps when idle and its contents change
as you edit. Each plan allows a limited number of shareable preview links at a
time.

## Deployments

A deployment is your project running for real, on its own stable public URL,
independent of your editing session. It does not sleep, it does not change when
you edit, and it stays up until you take it down.

**Deployment is gated by plan.** Each plan permits a fixed number of live
deployments, and on some plans that number is zero — meaning deployment is not
available on that plan at all and the only way to get it is to move to a higher
plan. Check the plan's limits to know which case applies.

Sandbox deployments are a separate, smaller allowance: short-lived deployments
meant for testing a build, not for serving real users.

A deployment can be **live** (running and serving traffic), **building** (the
current version is still being compiled), or **failed** (the build did not
finish, so the previous version — if any — is still what is being served).

## Folder upload

Folder upload brings an existing codebase in from your machine in one action,
rather than creating files one at a time. It is not available on every plan.

## Community sharing

The community gallery is a public collection of projects that other people can
open, read, and clone into their own workspace as a starting point.

Publishing to the gallery is allowed only on some plans. Cloning *from* the
gallery is allowed on every plan, including free — it is one of the standard
ways to create a project.
