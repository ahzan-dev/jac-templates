# Troubleshooting

## My preview is blank or will not start

A preview that has been idle sleeps and takes a few seconds to wake on the next
request — a blank screen that resolves itself shortly is usually just this.

If it stays blank, the cause is nearly always the code rather than the platform:
a build error, or an application that crashed on boot. The preview's log panel
shows the real error. A preview failing to start says nothing about whether a
deployment is healthy — they run separately.

## My deployment did not update

Editing files updates the **preview** immediately. It does not touch a
deployment. A deployment serves the version that was deployed to it, and it
keeps serving that version until you deploy again.

If a redeploy did not take effect, check the deployment's status. A **building**
deployment has not finished yet. A **failed** deployment means the build did not
finish, so the previously deployed version is still what visitors are seeing.

## I cannot deploy

Deployment is gated by plan and some plans do not include it at all. Look up the
plan's real deployment allowance before assuming anything is broken — an
allowance of zero means the feature is unavailable on that plan, and moving to a
higher plan is the only way to get it.

If the plan does allow deployments and every one of them is already in use,
taking down an existing deployment frees a slot.

## I cannot create a project

Every plan caps how many projects can exist at once. At the cap, creating
another one fails until an existing project is deleted or the account moves to a
higher plan. Deleting a project frees its slot immediately.

## My AI assistant stopped responding

The most common cause is an exhausted monthly credit allowance. Credits reset at
the start of each billing period. Everything that is not AI keeps working while
credits are out.

## I was charged but my plan did not change

Check the payment's status. A **failed** charge does not move the plan. A
**paid** charge that has not applied is rare and needs a human — open a ticket
with the invoice number.

## I lost work

Every project keeps its own git history and each save is committed, so previous
versions can be restored from the project's history rather than recovered by
support.
