---
title: The Plug and Chug Developer Mentality
date: 2021-04-23 08:00:00 -0600
author: joseph
---

A couple of weeks ago, I wrote about my reservations with [trusting open source]({% post_url /essay/2021-04-02-trust %}). But I think what's even more funny is how developers often reach for the same tools no matter what project they're working on. As soon as they work on a new project, they'll install the same packages and libraries that they've used before or that everyone else in the industry is using, no matter the requirements of the project they're working on.

Consider two different web applications:

One is a portal for customers to manage their relationship with a number of different business entities. The number of customers is very small, probably only a few hundred, coupled with only a few hundred business entities.

The other is a social network where users post little snippets of text that can be shared with different parts of their own network. The number of users is expected to be well over a hundred thousand.

These are two very different applications each with very different use cases, yet developers will often reach for the same tools without thinking.

## Asynchronous Processing

The very first tool they'll reach for is some sort of asynchronous background job processing, which means they'll want a message broker technology that's different from their relational database, like Redis or RabbitMQ.

But why?

To me it doesn't make sense to take on the overhead of learning and maintaining another additional technology unless the benefits outweigh the costs. An application with only a few hundred customers hitting it once or twice every day as opposed to a few hundred thousand have very different problems.

Instead, I'd much rather use an already existing technology within my stack to manage things like background job processing. PostgreSQL is a technology that most developers already understand, as it's almost always used as an application's relational database, so using it to manage background jobs won't add too much overhead.

It's also better to transition to a different technology later on down the road when the application *needs* it.

## Caching

The second tool developers will reach for is some sort of data store to manage their caching. Inevitably, developers will find that their application is "slow", and so they'll add a caching layer with `memcached` or Redis to speed their website back up to what they're expecting.

This is almost always the wrong solution to the problem.

Again, instead of adding an additional technology to your stack, which means everyone on your team needs to learn this new technology, look at your already existing technology to see if you can optimize there instead.

It's almost always the case that developers are using some kind of ORM or object-relational mapping. Relational databases like PostgreSQL are *optimized* for retrieving data, but most ORM query builders are horrible at optimizing those queries in turn. So instead, I would write the data in the shape it wants to be so that it can be retrieved more efficiently. This is called *denormalization*.

Instead something like this:

```sql
CREATE TABLE "users" (
  "user_id" UUID PRIMARY KEY,
  "email_address" VARCHAR NOT NULL,
  "name" VARCHAR NOT NULL
);

CREATE TABLE "posts" (
  "post_id" UUID PRIMARY KEY,
  "user_id" UUID NOT NULL,
  "text" VARCHAR NOT NULL
);

-- When querying user profiles.
SELECT
  "user_id",
  "email_address",
  "name"
FROM "users";

-- When querying posts with user information.
SELECT
  "posts"."post_id",
  "users"."user_id",
  "users"."email_address",
  "users"."name",
  "posts"."text"
FROM "users"
INNER JOIN "posts" ON "users"."user_id" = "posts"."user_id";
```

I may do something like this:

```sql
CREATE TABLE "users" (
  "user_id" UUID PRIMARY KEY,
  "email_address" VARCHAR NOT NULL,
  "name" VARCHAR NOT NULL
);

CREATE TABLE "posts" (
  "post_id" UUID PRIMARY KEY,
  "user_id" UUID NOT NULL,
  "text" VARCHAR NOT NULL,
  "user_email_address" VARCHAR NOT NULL,
  "user_name" VARCHAR NOT NULL
);

-- When querying user profiles.
SELECT
  "user_id",
  "email_address",
  "name"
FROM "users";

-- When querying posts with user information.
SELECT
  "post_id",
  "user_id",
  "user_email_address",
  "user_name",
  "text"
FROM "posts";
```

The second set of queries is almost always more performant than the first. Though this may mean that some data is duplicated, this in itself is not a mistake. If you're using a memory store like `memcached`, then you're already duplicating data, in both PostgreSQL and `memcached`.

And though this example may be a bit simplistic, imagine scenarios where the queries are even larger and more complicated, with nested inner queries and so on. With denormalization, you're duplicating data with intention and design.

## Containerization

The third tool developers will reach for is some sort of automated pipeline to deploy their code to their staging or production environment. And that tool will probably be Kubernetes.

While I think container technology like Docker is useful, it sort of obfuscates the underlying operating system. Since most applications will be deployed to some kind of Linux server, it makes sense to me for most developers to have some facility with the same operating system they'll be deploying to. Yet tools like Docker and Kubernetes obscures these things in favor of their own domain-specific language.

Automated deployments is worth doing in my opinion, but Kubernetes is overkill for most use cases. It's overly complex and requires a whole team to manage any infrastructure created with it.

Much simpler in my mind to clone virtual machines into images and deploy those in auto-scaling groups. In almost all cases, I prefer working as closely to the bare metal machine as I can, and if that's not possible, to the virtual machine in question. Tools like Docker and Kubernetes adds a layer of abstraction that just confuses things.

## Conclusion

So why do developers do this? Part of this I think is because developers read what other developers do and think that this must be The Way Things Are Done. Maybe they're trying to pad out their resume by gaining experience in the latest, hottest technology.

But what this all speaks to is a lack of design. Following the leader is not an adequate reason to do something. Just as each line of code needs to be added for a specific purpose, each technology introduced into a stack needs careful thought and intention.

Otherwise, your project will end up like everyone else's: a big pile of mud.
