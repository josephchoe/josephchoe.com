---
title: "Event Sourcing, Part 1: User Registration"
date: 2021-01-29 08:00:00 -0600
author: joseph
---

> **Note:** Be sure to check out my 11+ hour video tutorial on [event sourcing]({% post_url video/2021-07-02-event-sourcing-tutorial  %})!

Event sourcing is an unexplored space in the Ruby landscape, with very few resources detailing how to build and design such systems. Therefore, I'm going to talk about how to build an event sourced system through a sequence of four, maybe five, essays, with actual written code examples.

I'm not going to talk about *why* you should write event sourced services. That in itself is a pretty huge topic and could be its own sequence, and one I don't really feel equipped to talk about now.

But sometimes learning is best done through doing.

## Disclaimer

This essay is a tool for learning. I would never advocate using code found on the Internet somewhere and copying it wholesale into your production systems. Read the essay to the end, as well as the following parts of the sequence when they come out, and discover for yourself whether there's anything useful to learn here. It's important to understand *every line of code* you put into your own systems.

## A Minor Tangent

I first learned about event sourcing by watching a GOTO 2014 conference video with Greg Young where he talked about event sourcing, CQRS, and DDD. He talked about how there was another way to do software development.

When I first saw that video, I felt like my eyes were opened. I had been working on legacy monoliths of one stripe or another for a long time, first in C# and then in Ruby. But the same problems always reared their ugly heads, no matter the language used. Here it seemed was one piece of a missing puzzle that allowed me to look beyond basic web development into a more coherent architecture.

Another piece of that puzzle was filled when I took the course Advanced Distributed Systems Design by Udi Dahan and learned about **Service-Oriented Architecture**. A lot of what he said made sense, and I really began to understand the shape of what distributed systems should look like and why.

But the problem here was that there were no concrete examples of how to *build* these systems. There was a lot of theory but not a lot of practical application of that theory. Neither Greg Young nor Udi Dahan could avail me, and I suppose I could understand their implicit reasoning. Building such systems is a full-time job in itself, and it doesn't make any sense to write code for free, especially when that's your primary skillset.

Yet even their paid resources and courses are relatively sparse on how to build such things. You had to hire these people or someone like them as consultants to teach you or build them for you.

That's when I found [Eventide](https://eventide-project.org).

## The Eventide Project

Co-founded by Scott Bellware and Nathan Ladd, the Eventide Project is a toolkit for building event sourced components or services in Ruby. Luckily, they provide examples of how to build services, though if you come from a purely Rails background, you may find their example projects to be a little esoteric and strange. Where's the `app` directory? Where's the `Rakefile`? Where's `Gemfile.lock` and all the other things I expect to see in a Ruby project?

You must set aside the notion that the Rails way is the *only way* in a Ruby project. Rails does not equal Ruby, yet the former may seem to encompass the entirety of what the latter has to offer. Nothing could be further from the truth!

Eventide's primary examples are an [account bank balance](https://github.com/eventide-examples/account-component) and a [funds transfer between two accounts](https://github.com/eventide-examples/funds-transfer-component), which are great as a primer into Eventide. But not all web applications are banking applications, and so I think it might be useful to cover examples that most web developers might be familiar with.

## User Registration

User registration is one of those problems nearly every developer has to face, but like most problems always differs in the details. Perhaps you need to collect name, address, and other pertinent information. Maybe you just want an email address. And if you're one of those people who have to deal with storing their own passwords, you have my deepest sympathies.

For now, we'll just deal with a simplified form of user registration and collect only an email address from a user. What I like to do is to start with the entity and work my way to the different messages, and then onto the projection and handler.

## The Registration Entity

The [entity](http://docs.eventide-project.org/glossary.html#entity) is a good place to start, because it allows you to see and develop the core logic of the business process in question, which in this case is the process by which our application registers users.

```ruby
class Registration
  include Schema::DataStructure

  attribute :id, String
  attribute :user_id, String
  attribute :email_address, String
  attribute :registered_time, Time

  def registered?
    !registered_time.nil?
  end
end
```

The registration has an ID, which may be `registration_id` in other contexts. It also has an `email_address`, because that's what we're collecting; a `user_id` associated with the `email_address`; and a `registered_time`, or the time the user registered to our application. There's also a predicate method called `registered?` to let us know if a Registration was previously registered. This has to do with enforcing idempotence, which I'll talk about later.

## Where's the User Model?

Most object-oriented programmers try to "find the nouns", but that can be fairly misleading. Services don't model nouns, but instead model business processes. Especially in a language like Ruby, where the dominance of Rails colors any sort of thinking on the subject, nouns or models are tightly coupled with `ActiveRecord`, which means they're coupled to ideas of database persistence.

You can see this in Rails article after article on the subject of "service objects", somehow implying that these "service objects" are different from normal objects. But objects are simply data structures tied to a specific behavior via their functions. So the word "service" in service object doesn't impart any special meaning.

Or you may think of the doctrine of "fat models, skinny controllers", where you put all business logic pertaining to Users in the User model. That *seems* to be object-like, right? But Users aren't a business process, and the User model is mostly about loading tuples from the database.

You very well *might* have a User object, but keep in mind that the concept of User is malleable, depending on the context. If I was an admin viewing a report, I might have different functions or behaviors available to me regarding the concept of User than if I was that user and viewing my own profile. This is what you might see called *bounded context* in Domain Driven Design, though that's beyond the scope of this essay.

In any case, when I speak of business processes, I mean any process that helps facilitate your business. While that may be tautological, it means any process that helps you gain customers and keep those customers. This could be the collection of billing information, customer engagement with your platform, or as in this case user registration or sign ups.

So instead of Rails models, we have an entity, which is an object that encompasses the entirety of the data attributes and logic needed to represent the registration business process. If it looks simple, that's  because you don't really need anything else.

## Messages

Now that we have our registration entity, we'll want to address our [messages](http://docs.eventide-project.org/glossary.html#message). In service-oriented architecture, we pass messages back and forth through the medium of the message store. These can come in two kinds: commands and events. Commands are things you tell the service to do, while events are things that happened within the service.

Let's take a look at our command:

```ruby
class Register
  include Messaging::Message

  attribute :registration_id, String
  attribute :user_id, String
  attribute :email_address, String
  attribute :time, String
end
```

And our event:

```ruby
class Registered
  include Messaging::Message

  attribute :registration_id, String
  attribute :user_id, String
  attribute :email_address, String
  attribute :time, String
  attribute :processed_time, String
end
```

They both look much the same as our entity, though without any business logic, just a bag of data attributes. The primary difference between command and event is that the event has the addition of a `processed_time` attribute. This lets us know when a component processed that particular message, which is different from the `time` attribute, which is the *effective* time of that event.

If we think of our registration, the effective time a user registered to our application can be different from when our service processed that registration, because in an event sourced system messages are processed asynchronously.

## Projection

[Projections](http://docs.eventide-project.org/glossary.html#entity-projection) are used to construct an entity from a sequence of events. The projection for our registration is pretty simple, mostly because it applies only one event.

```ruby
class Projection
  include EntityProjection
  include Messages::Events

  entity_name :registration

  apply Registered do |registered|
    registration.id = registered.registration_id
    registration.user_id = registered.user_id
    registration.email_address = registered.email_address
    registration.registered_time = Clock.parse(registered.time)
  end
end
```

In many ways, software development is simply about copying or moving data from one place to another, and that is no different here. We're copying the attributes of the event into the entity, with some parsing and data transformation.

Note that when the Registered event is applied, the `registered_time` attribute becomes set, which means our `registered?` predicate from the Registration entity will go from `false` to `true`.

```ruby
class Registration
  ## ...

  def registered?
    !registered_time.nil?
  end
end
```

## Handler

[Handlers](http://docs.eventide-project.org/glossary.html#handler) are the most complicated part of the component, in my opinion, and require an understanding of what is going on behind the scenes, i.e. hidden within the framework code.

The message store is an append-only log, with each tuple in that log representing a message, i.e. a command or an event. The component queries the message store for messages within a specific category and processes those messages sequentially. In this case, our handler is processing messages from the `registration:command` category, a category of command messages for the registration component.

A category could have multiple streams, each one an individual entity. For example, `registration-123` and `registration-456` would represent different registration entities but belong to the same registration category.

Let's look at the code.

```ruby
class Handler
  include Log::Dependency
  include Messaging::Handle
  include Messaging::StreamName

  dependency :write, Messaging::Postgres::Write
  dependency :clock, Clock::UTC
  dependency :store, Store

  def configure
    Messaging::Postgres::Write.configure(self)
    Clock::UTC.configure(self)
    Store.configure(self)
  end

  category :registration

  handle Register do |register|
    registration_id = register.registration_id

    registration, version = store.fetch(registration_id, include: :version)

    if registration.registered?
      logger.info(tag: :ignored) { "Command ignored (Command: #{register.message_type}, Registration ID: #{registration_id}, User ID: #{register.user_id})" }
      return
    end

    time = clock.iso8601

    stream_name = stream_name(registration_id)

    registered = Registered.follow(register)
    registered.processed_time = time

    write.(registered, stream_name, expected_version: version)
  end
end
```

We have something very similar to the projection above, but the difference is that the projection reads events from a single stream within a category, while the handler reads messages from the entire category.

The first few lines of the `Handler` class are dependencies. The `configure` method is especially interesting for Ruby code, but not something I'm going to go into this essay. Instead, let's look at the `handle Register` block.

The Registration entity is fetched using the `store` object. The store reads the events in the entity's stream and feeds them into the projection, which moves the event message data into the entity.

We can then use this registration entity to make business decisions with. Here we are using the `registered?` predicate to determine whether the registration entity was previously registered so as to avoid registering it again.

## Never Forget Idempotence

Idempotence is the idea of processing messages more than once but actuating any side effects, i.e. writing to the database or calling external dependencies, only once.

In all messaging systems, there is the very real possibility that messages will be processed more than once. This can occur in two forms. The first is because a service is restarted and messages that were already processed are processed again. The second is due to duplicate command messages. For example, two `Register` command messages with the exact same data attributes were erroneously written to the message store.

Making handlers idempotent is important. If you've ever come across a system in the wild that disables the `Submit` button upon clicking or warns against clicking a button multiple times for fear of charging your payment information more than once, you've seen a system that is not idempotent.

Here we use the `registered?` predicate to make sure that a `Registered` event is not written to the stream if it was already done so previously. This is because we project the stream prior to making any writes to the message store, so we have up to date information on the stream.

## Handler, continued

The final block of code details writing the `Registered` event to the `registration-{registration_id}` stream.

```ruby
class Handler
  ## ...

  handle Register do |register|
    registration_id = register.registration_id

    registration, version = store.fetch(registration_id, include: :version)

    ## ...

    time = clock.iso8601

    stream_name = stream_name(registration_id)

    registered = Registered.follow(register)
    registered.processed_time = time

    write.(registered, stream_name, expected_version: version)
  end
end
```

The first line sets `time` to the current time in ISO 8601 format. The next line sets the `stream_name` with a handy convenience method that concatenates the category name with the `registration_id` so you end up with `registration-{registration_id}`.

The `follow` method is another one of those convenience methods provided by Eventide that copies all of the data attributes from the preceding message into the new message.

Finally, we set the `processed_time` to the `time` variable discussed above and write the message to the message store.

## What about Concurrency!

One more thing I want to note is the `expected_version`. This is a form of optimistic locking and prevents our component from writing events to the stream concurrently. This could happen if there are two instances of the component running by mistake, for example, which we realistically don't want to happen but need to protect against.

When we first fetched the registration entity, we also received a `version`, which was the version number of the last message of the stream. When a message is written to the message store, each stream keeps track of the version of the event. The first event of the stream will be 0, while the next event will be 1, and so on sequentially. An empty stream will have a version of -1.

Because we've fetched the version from the store, we can pass that version into the writer. This will check to make sure that the expected version of the stream, i.e. the version of the last event of the stream, matches what is passed in before writing the `Registered` event to the message store. If the expected version does not match, then a `MessageStore::ExpectedVersion::Error` exception will be raised, and the entire component will stop.

Otherwise, the `Registered` event will be written to the message store, and the next message in the category will be processed.

## Conclusion

We've learned how to code the basic bones of an Eventide component, with the nominal use case of user registration. We've learned about entities, messages, projections, and handlers. We've made our handler idempotent and protected against concurrent writes.

However, this component is still incomplete. When we think of the user registration use case, we want to make sure that people can't sign up to our application with the same email address. In other words, we want email uniqueness. Yet, this component doesn't take email uniqueness into account.

Which is what I plan to discuss in the next part of this sequence.
