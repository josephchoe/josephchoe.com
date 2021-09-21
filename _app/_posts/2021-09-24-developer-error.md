---
title: Developer Error
date: 2021-09-24 08:00:00 -0600
author: joseph
---

There arose a situation this week where two developers discussed a design that I was sure was a mistake. As I sat there listening, I wondered whether I should continue to [observe]({% post_url 2021-09-10-farming-metaphor%}) or if I should intervene in some way.

To me it's better to guide others along until they reach the conclusions I want them to reach themselves and in their own way. But I suppose there are certain times where it's easier and maybe even better to nip certain things in the bud. It's a difficult thing to navigate.

This recalled to mind another situation early in my software development career. Rather than recount the present, let us delve into the far distant past to illustrate what I saw wrong with the situation at hand.

I was tasked with developing a web application with simple user access controls. When the user logged in, they would be able to see certain pages that the general public would not be able to see.

This is obviously an overly simplistic example, but time has eroded the memories away, so please forgive me for the lack of detail.

The CEO and founder of the company came to me directly and asked me for an ironclad guarantee that any members only page would not be accessible by the general public. Not only that but that any developer or operator would not be able to circumvent this check erroneously or purposefully.

I think the context for this was that a page had previously been deployed where this check was not in place, therefore certain private information had been made public. I'm rather vague on the details only because I hadn't really been involved prior to that point.

Let us set aside how many things have to go wrong for a CEO to circumvent the hierarchy and approach a developer directly for confirmation rather than trust in the processes that they themselves set up. Unfortunately, this sort of dysfunction is surprisingly common in the industry.

Back then I was an inexperienced developer lacking the tools necessary to interact well with the executive leadership. I imagine that what I said was, ["That's impossible."]({% post_url 2021-04-09-impossible %})

However, I think what I instinctively knew back then was that this kind of ask is not really possible via code or developer tooling. I see many of these types of safeguards in things like type checking a dynamic language and other tools "to protect the developer from themselves".

Instead what the executive leadership should have done was to strengthen other processes. Test early and often so these kinds of mistakes are caught early. Deploy applications frequently until they become routine, rather than weekend affairs. Mentor and train developers so they can be instilled with the necessary discipline to avoid making simple mistakes.

But I suppose most companies enjoy having easy solutions available to them, even if they wouldn't work. They misunderstand what technology is useful for and what is impractical to implement.
