---
title: Technical Assessments Are Dumb
date: 2021-02-05 08:00:00 -0600
author: joseph
---

Over the last year and throughout my career as a software developer, I've had the dubious pleasure of taking countless numbers of technical assessments, coding challenges, take-home assignments, et cetera, and I can unequivocally say that technical assessments are a complete waste of time.

Though I speak from the perspective of a software developer, I've also been on both sides of the table, having conducted interviews for an equally countless number of candidates. Even from that perspective, they're a waste of company time. All these assessments do is tell me that a company isn't serious enough about their own Technology department to assess the people they're hiring into their company. They're playing follow the leader instead.

Here's why.

## Pointless Faffery

Consider the conditions of a typical technical assessment. They can take many different forms.

1. You're on the phone and someone asks you a series of questions. Describe polymorphism. What are the differences between a hash table and a binary search tree? What is REST and how does it map to Rails controller actions? (Company: Hotel Engine)
2. You're in a conference room, and you're asked to write code on a whiteboard something like an adjacency list or merge sort. (Company: Google)
3. You're on an online coding pad and have thirty minutes to write an anagram detector. (Company: Mighty Networks)
4. You're brought onsite to fix a real bug from the company's backlog. (Company: Pivotal)
5. You have a take-home coding challenge. (Company: [Takko](/assets/posts/2021-02-05-technical-assessments-are-dumb/takko.pdf), [Vangst](/assets/posts/2021-02-05-technical-assessments-are-dumb/vangst.md), and [Everlywell](https://github.com/josephchoe/backend-challenge))

These are but a smattering of the kinds of technical assessments I've received over my career. I'm calling out actual companies by name, because I believe the software development industry needs a massive overhaul in how they assess technical skill, and change does not occur without shame.

I submit that any company that does any of the above doesn't know what they're doing, and they don't care about their employees all that much either. The only thing assessments such as these do is filter candidates by some arbitrary measure. They certainly do not impart any information regarding the candidate's ability to develop software.

Let's address these one by one.

### I'm Not a Recent College Graduate

The first form is typically geared towards recent college graduates, where they've learned data structures, algorithms, and the like in college. They certainly aren't used in most software development jobs, or if they are, they're already a standard part of the library. Most software developers, especially senior developers who've been working for anywhere from five to twenty years, haven't cracked open a textbook in ages, and yet when they're between jobs, suddenly they have to revisit those same textbooks.

Of course, some companies won't ask questions from a college textbook, but the sentiment is much the same. You're basically taking a quiz and expected to give the correct answer. There's a kind of one-upmanship that many software developers seem to engage in to show how much more they know than their fellow colleagues. I think that kind of thing is pretty tiresome, but it's prevalent in the industry, and I think that's on display here.

### I Don't Write Code on Whiteboards

The second form, i.e. whiteboarding, completely misses the point of how software developers build applications. If there's collaborative design work going on, then sure, there might be whiteboarding sessions here and there, but they're unlike anything that takes place during any technical assessment. Software design work is more about assembling the pieces of a system in your mind. You see a lot more drawing of boxes and arrows, rather than the writing of pseudocode or even real code.

No one is writing real code on a whiteboard in their professional daily work. They write code on a computer.

### I Don't Code with Arbitrary Limits

The third form has two separate problems. The first is that coding challenges are often extremely simplistic and don't reflect real work. They're often simple problems that are easy for the employer to evaluate, like FizzBuzz or determine whether two words are anagrams of each other. Yet, it can be an incredibly stressful atmosphere if you haven't seen the problem before or in a long while. You're trying to think on your feet, which is not typically how developers work.

The second problem is that they place arbitrary restrictions that would not exist in a real working environment. For example, software developers use the Internet to find solutions to work that others have already solved. They also use it to look up terms they might not know or have forgotten. Yet most companies restrict the use of the Internet during technical assessments.

Another example is the arbitrary time limit of thirty minutes or an hour. These time limits  don't really exist in software development. Well, there *are* time limits of a different kind, i.e. time estimation, but that's a topic for a different essay. What I mean is that I don't typically write software in 30 minute or one hour chunks. When I write code, I need a block of four to eight hours minimum, because most of a programmer's time isn't spent with hands on keyboard, but instead deep in thought or researching some problem.

But when a company places arbitrary time limits, they're basically adding stress to an already stressful situation. It's not really a great way to assess a candidate's best work, is it? Especially when that work is something as dumb as finding anagrams or palindromes. Yet even if they're dumb, they also run into the next problem.

### I Don't Write Code for Free

The final two forms suffer from the same problem. As a software developer, my livelihood *depends* on me writing code and developing software in exchange for money.

So when a company asks me to spend significant chunks of my own personal time to write code for them without offering to pay my market rate in return, I know they don't respect me or my time. They're the same kind of people who ask artists to do free work in exchange for "exposure", and it's just as **despicable** a practice there as it is here.

## But Google Does It!

The people at Google and others of the Big Four are the worst offenders. But let's examine this for a moment and grant that Google has good reason to run their technical assessments this way.

However, what reason do other companies have to play follow the leader? Most companies aren't at Google's scale. They're not running search engines or large distributed systems emplaced worldwide. Their IP is not based on complex algorithms or vast social networks. They're not running a million transactions per minute.

Instead, they're doing what I like to call "moving data from one place to another." This problem is unique to each business, but once you've done it once, you're well placed to be able to do it again in other contexts.

What these companies have done is taken an interviewing strategy from a vastly different company and tried to apply it to their own. But like all solutions you read about on the Internet, you need to first evaluate whether it fits your own use case.

And I'm certainly not going to let Google off the hook. Like I said before, not one of the above assessments allows you to answer the most important question about the candidate, which is whether they know how to develop software. They're basically pointless ceremonies and rituals used to filter out candidates by some arbitrary measure. Most of the people giving out these assessments would *fail* their own tests. I've failed plenty of them, yet I'm still capable of writing software.

And those assessments that *do* evaluate real work are basically exploiting workers by asking them to work for free.

## The Solution

It's not my job to tell employers how to do theirs, but I am drawing a line in the sand. I now **refuse** to take part in any of the above technical assessments, *especially* if I am not being paid my market rate. The only company who has paid me real money during a technical assessment is [Nadine West](https://nadinewest.com/), and I'm only naming them because I think calling out good behavior as well as bad is necessary to spark change.

I *might* consider showcasing some code I've written or am particularly proud of during an interview or submitting a portfolio of code. I'll even complete a take-home challenge, but only if I'm being paid for my time. Otherwise, I think bringing on candidates and paying them for a preliminary period of a month or so is the best way to assess technical skill.

It is far, far easier for an employer to take a punt on an employee for a couple of weeks to assess their skill level than it is for a worker to take a chance on a company. Especially if said company has closed a multi-million dollar series funding round or is an enterprise-level company  with several thousand employees. Compare that to most workers who live paycheck to paycheck. They don't have the time or resources to jump through pointless hoops. If an employer is incapable of treating their workers with a basic modicum of respect, then they shouldn't be hiring in the first place.

Now before anyone accuses me of entitlement and privilege, I recognize that I possess a skillset that very few do, one that is fairly lucrative (for now). Even so, I think that technical assessments as they currently exist are dumb and need to change. I also know that taking this particular hardline stance will cost me opportunities and jobs in the future, but that is a sacrifice I'm willing to make in order to change even a single company.

Interviews are not only about companies assessing a prospective candidate, but also about the workers learning more about their future employer. Technical assessments like the ones above should act as a signal to run far, far away.
