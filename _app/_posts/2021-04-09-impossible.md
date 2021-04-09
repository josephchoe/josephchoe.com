---
title: That's Impossible
date: 2021-04-09 08:00:00 -0600
author: joseph
---

There are few things I dislike more than hearing the words, "That's impossible," in the context of software development.

If we as programmers are being perfectly frank with ourselves, there's not a whole lot of difficulty in software development, especially web development. I say this a lot, but it bears repeating: software development is simply about copying data from one place to another. Barring

So when I hear developers say, "That's impossible!", I wonder if they're really trying all that hard.

I remember one particular instance where I was reading a frontend developer's pull request, when I noticed something strange (yes, I was [snooping]({% post_url 2021-02-19-snooping %})). They had used `jquery` and javascript event listeners to do something that could have been done in a single line with the framework we were using at the time, but for some inexplicable reason had not done so. The code was messy, untested, and prone to failure.

I went up to their desk and asked why they'd done that instead of using the framework, and they replied, "That's impossible."

I was not amused.

What this developer, and most developers to be honest, meant when they said X was impossible was that they'd found a solution to their particular problem, and they weren't going to look for another, despite the fact that what they had done damaged readability and maintainability for future developers.

I've found that very few developers will keep the more implicit aspects of software development in mind when writing software. They're mostly looking to bang out some code than do real design work. Most of this is the surrounding culture of the company, I suppose. If you have an artificial deadline imposed by Scrum, you're liable to take shortcuts in your own code. You learn from other software developers around you, and if they're shipping subpar code, then you probably will, too.

But in this particular case, I think the developer was just being lazy.

I ended up spending an hour pair programming with them to show that it *was* possible, and it only took that long because I wasn't really familiar with the framework in the first place, as I'm not a frontend developer.

But every time I hear another developer say some particular thing is impossible, I think about the above story, and I grimace.
