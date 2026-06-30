+++
title = "Software sucks"
date = 2026-06-30
updated = 2025-06-30
description = "Expressing my frustration with modern software"
authors = ["Behemoth"]
+++

We are not multiple years into software being solved.
Sadly one area that is still save from 100x improvements is user interfaces.

Every day I have to deal with horribly slow software and I'm so sick of it.
At work I have to deal with Windows Explorer. A piece of technology so notoriously slow that third party file explorers are now trending.
At least last year Microsoft has added tabs but they are still poorly integrated. They take forever to load, flashbang me every other time and middle-click is very inconsistant.
The new right-click is attrocious. Besides destroying decades of muscle memory, the new buttons move around.
They had a chance to fix the old shitty application hook-ins but now we have multiple new issues.
The old hooks (`IContextMenu`) are hidden behind a "more" button.
The new ones take multiple seconds to show up. They show a placeholder in the meantime, which cause a layout shift after they laoded.
For some reason thumbnails also don't load correctly for me.
Accessing a network share which isn't reachable causes the entire window to become unresponsive until we eventually run into a timeout. No feedback at all.
Use [File Pilot](https://filepilot.tech/) instead.

I think the task bar is still part of the explorer process and it also has issues with inaccessible network drives.
If you have a link to an exe on a network drive and that drive disappears, good luck fixing that link.
You can't even right-click the damn thing.
The start menu sucks so fucking much nowadays.
If I wanted to search the web, I wouldn't open the fucking start menu.
And, of cause, it's not just a menu button.

Every day I see multiple error screens from Citrix.
I had to install it to service one customer.
It instantly started registering three autostarting applications.
I fail to understand why a program that acts as a fancy RDP URL handler needs that.

I have to use Jira. I want to check my tickets, I wanna read them, read the comments. Move them to another state or assign someone else to a ticket.
It's attrocious. I can't open multiple tickets at the same time. Middle-click just doesn't work. I have to open the popup screen, locate the actual ticket ID and then right-click.
Trying to copy text moves me into the edit mode. This is somehow cached and I have to actively click cancel, otherwise I'll miss all incoming edits from everyone else.
Recently they have integrated their LLM and now every uppercase word is highlighted and "Rovo" offers me an explanation for "NOT". Thankfully there are ublock origin rules to [kill it](https://github.com/alechenken/disable-Jira-Rovo). Naturally there is no config to disable it.
For some reason, jira decided to open files in the browser instead of downloading them.
MSG embeds as just the plain text while EML presents you with the equivalent of running `strings` on it.
In their defense, even the new outlook can't open MSG files!

Talking about SourceTree is beating a dead horse at this point.
Atlassian doesn't put any effort into maintaining it anyway.
It's slow and you can't even look at your diffs properly.
The graph is neat.
Use [Sublime Merge](https://www.sublimemerge.com/) instead.

Microsoft Teams is another practical joke that is played on me every day. The sole reason why any organisation uses it is probably that they don't have to pay extra because Microsoft prices it into every Office 365 subscription.
It fails in so many aspects that I wonder if the people who concepated, planed and executed even drink their own cool aid.
Maybe you remember it used to be worse. Scrolling would be capped to five messages every 5 seconds. The recent-ish rewrite made it more bearable.
But still, messages don't get delivered half the time. Sometimes I see the notication bell in the corner which prompts me to click through every single chat to see what the notification was for.
I get logged out of external tenants without any notice, making me miss more messages.
It also tries to sell you some premium subscription.
Sometimes it descides to overwrite the link handler with Edge again.
The two options are "Edge" and "default browser". I hope they get sued and loose.

Switching to rustdesk is genuinly an eye-opening experience for some people.
It is so much faster than TeamViewer. The current version of TeamViewer takes MINUTES to open. The "old" version still takes around thirty seconds on my machine.
rustdesk? Cold start takes a second. From there, imperceivable.
If you still pay for that slow, overpriced, privacy violating crap, switch to [rustdesk](https://rustdesk.com/).

Visual Studio is another annoying piece of technology.
It got faster in recent years but it's still not great.
Especially with extensions like ReSharper running, it's so slow.
Worse than an incomplete tool, is an unreliable one.
Half my inputs are swallowed.
The diagnostic links send you to bing chat now.
The old docs page has been dead for a while.
The nuget integration is unusable.
It is impossible to update multiple dependent packages to a version that is not the highest one.
It will abort after the first conflict and the UI offers no way of rectifying it.
Luckily you can now use the `Directory.package.props` to manage all nuget versions in one place.
But beware. The nuget manager also touches this file and wrecks your indentation and remove all double-newlines.
Add pre-commit hooks or drill your coworkers to either not use the nuget manager or always re-format that file.
Sadly some legacy crap is feature gated to Visual Studio so just switching to a different editor is not always a posibility.
Hot-Reloading was added to vscode now but only the proprietary version.
Watch [this video](https://www.youtube.com/watch?v=GC-0tCy4P1U) by Casey Muratori if you haven't already.

If you ever thought it was a great idea to do OAuth in your integrated WebView, stop it. Get some help.
I don't want to copy my credentials again and I don't want to wait for the confirmation E-Mail or pull out my 2FA code.
I'm already logged into my browser. Android Apps are particularly guilty of that.

The Azure team gave up on documenting Entra properly so you should probably give up on using it.
Currently there are 4 ways to access the same data. Over the Azure Portal and the Entra Domain, both with an old and a new UI.
It's a gamble which buttons work. Each documentation page randomly references one of them.
Good luck figuring out what to do where.
Maybe the next time they rename it, it will be good.

Github enterprise sucks too.
In weird ways.
Refresh tokens aren't utilized properly so you constantly get kicked out.
It lags behind the public version by so long that your CI gives you deprecation warnings that you can't fix because the new packages are not available.
Half the time the integration in Visual Studio sends you to the wrong page.
