---
title: "Event Sourcing, Part 3: Publish and Subscribe"
date: 2021-03-26 08:00:00 -0600
author: joseph
---

> **Note:** Be sure to check out my 11+ hour video tutorial on [event sourcing]({% post_url video/2021-07-02-event-sourcing-tutorial %})!

Over the last two months, I've talked about how to build event sourced components. One of these components accepts [user registrations]({% post_url /essay/2021-01-29-event-sourcing-part-1 %}), while the other handles [email uniqueness]({% post_url /essay/2021-02-26-event-sourcing-part-2 %}).

My goal in this sequence of essays is to demonstrate how to build event sourced systems. But before we can get into things like how to paint a user interface screen, we need a way for one component to communicate with the other. Let's discuss that today, with code examples to demonstrate.

## Disclaimer

This essay is a tool for learning. I've intended the below code for that purpose and *not* to be used in production environments. Read every line of code and make sure you understand each and every implication. Exercise your best judgement when taking code found on the Internet and putting it into your own codebase.

## It's All about Communication

Event sourced components communicate through messages. These messages, whether commands or events, are recorded in a message store, which in Eventide's case is a single immutable `messages` table in a PostgreSQL database.

```sql
CREATE TABLE messages (
  global_position bigserial NOT NULL,
  position bigint NOT NULL,
  id UUID NOT NULL DEFAULT gen_random_uuid(),
  time TIMESTAMP WITHOUT TIME ZONE DEFAULT (now() AT TIME ZONE 'utc') NOT NULL,
  stream_name text NOT NULL,
  type text NOT NULL,
  data jsonb,
  metadata jsonb
);
```

Because of this, any service can read from any stream in the `messages` table and react to each message accordingly, without any knowledge of the producer of that message, except perhaps two things: the name of the stream they're reading from and the contract of the messages therein.

It's a simple `SELECT` query. Indeed, the broadcasters of those messages can have no idea who exactly is reading their messages.

This is typically known as the **publish-subscribe** messaging pattern.

But not only that, services can also send messages to other specific services, if they know the command stream name of the service in question. For example, our user registration component from Part 1 has a command stream where it reads `Register` command messages and writes `Registered` events.

But we don't know where those messages are coming from. They could be coming from another service, or perhaps from a resource endpoint within a Rails controller. They could even be generated from a CSV file that's uploaded to an FTP server.

All we know for certain is that our components read messages from one stream and react to them by writing messages to another.

With these tools in hand, we can have our components communicate with one another.

## User Registration, Revisited

For our purposes, the email uniqueness component is complete. It has no need to have any knowledge about anything outside of itself, therefore we won't be making any changes to the component.

However, in order for the user registration component to utilize email uniqueness, we'll need to make a few changes to that component in particular.

```ruby
class Registration
  include Schema::DataStructure

  attribute :id, String
  attribute :user_id, String
  attribute :email_address, String

  attribute :initiated_time, Time
  attribute :email_accepted_time, Time
  attribute :email_rejected_time, Time
  attribute :registered_time, Time
  attribute :cancelled_time, Time

  def initiated?
    !initiated_time.nil?
  end

  def email_accepted?
    !email_accepted_time.nil?
  end

  def email_rejected?
    !email_rejected_time.nil?
  end

  def registered?
    !registered_time.nil?
  end

  def cancelled?
    !cancelled_time.nil?
  end
end
```

The Registration entity has quite a bit more going on with it than the last time we saw it. The first three attributes are much the same. But next we have a series of `Time` attributes.

This is because we need a way to track the different states the registration is in. We need to know when we've begun the registration process, and we need to know when the registration has completed, either from the email address being accepted or rejected.

You can see this entity as a **finite-state machine**, with two divergent paths. One of them being from `Initiated` to `EmailAccepted`, and finally to `Registered`. But we also need to take into account the failure mode, where the email address was already claimed in a previous registration. That leads us down the path from `Initiated` to `EmailRejected`, and then to `Cancelled`.

## Messages

I'm not going to show the messages in full because many of them you've already seen before, so there's not much to discuss there. But also because they're basically copies of one another with different class names.

```ruby
class Register
  ## ...
end

class Initiated
  ## ...
end

class EmailAccepted
  ## ...
end

class EmailRejected
  ## ...
end

class Registered
  ## ...
end

class Cancelled
  ## ...
end
```

Like I've said before, software development is simply about copying data from one place to another. Rinse and repeat.

Also, there are a lot of messages. Just imagine them all having the same exact attributes.

## Projection

The projection here is fairly straightforward. We have a bunch of events that copy data into the Registration entity.

```ruby
class Projection
  include EntityProjection
  include Messages::Events

  entity_name :registration

  apply Initiated do |initiated|
    registration.id = registered.registration_id
    registration.user_id = registered.user_id
    registration.email_address = registered.email_address
    registration.initiated_time = Clock.parse(initiated.time)
  end

  apply EmailAccepted do |email_accepted|
    registration.email_accepted_time = Clock.parse(email_accepted.time)
  end

  apply EmailRejected do |email_rejected|
    registration.email_rejected_time = Clock.parse(email_rejected.time)
  end

  apply Registered do |registered|
    registration.registered_time = Clock.parse(registered.time)
  end

  apply Cancelled do |cancelled|
    registration.cancelled_time = Clock.parse(cancelled.time)
  end
end
```

Each event applies the `time` attribute to the entity in the corresponding place, which we know is important for our predicate methods.

## Handlers

Here is where things wildly diverge from the original User Registration component. Instead of writing a `Registered` event in response to a `Register` command, we need to kick off our state machine by writing an `Initiated` event.

```ruby
module Handlers
  class Commands
    ## ...

    handle Register do |register|
      registration_id = register.registration_id

      registration, version = store.fetch(registration_id, include: :version)

      if registration.initiated?
        logger.info(tag: :ignored) { "Command ignored (Command: #{register.message_type}, Registration ID: #{registration_id}, User ID: #{register.user_id})" }
        return
      end

      time = clock.iso8601

      stream_name = stream_name(registration_id)

      initiated = Initiated.follow(register)
      initiated.processed_time = time
      initiated.metadata.correlation_stream_name = stream_name

      write.(initiated, stream_name, expected_version: version)
    end
  end
end
```

Most of the write logic you'll see in this essay is something you've already seen before, only applied in different ways. But note the `correlation_stream_name` written to the `Initiated` event's metadata.

Within the Eventide toolkit, you have a lot of different metadata. For example, the causation stream name is used to denote which stream caused the message to be written. Another way to look at it is which stream did the preceding message come from? For example, the `Initiated` event's causation stream name is the command stream name or `registration:command-{registration_id}`, while any message following the `Initiated` event will be `registration-{registration_id}`. And so on and so forth.

The correlation stream however is a bit different. Every single message in the long chain of messages we'll be writing will have the same correlation stream name, because the correlation stream name is simply copied over whenever one message follows another. Put another way, the correlation stream name allows us to know the originating stream name of any message in the chain, even if they should happen to span different components and different streams.

Next, once we have written an `Initiated` event, we need to write a `Claim` command to the email uniqueness component, to let that component know we want to claim an email address.

```ruby
module Handlers
  class Events
    ## ...

    handle Initiated do |initiated|
      registration_id = initiated.registration_id
      user_id = initiated.user_id
      email_address = initiated.email_address
      encoded_email_address = encode_email_address(email_address)

      claim = Claim.new
      claim.metadata.follow(initiated.metadata)

      claim.claim_id = registration_id
      claim.encoded_email_address = encoded_email_address
      claim.email_address = email_address
      claim.user_id = user_id

      stream_name = "userEmailAddress:command-#{encoded_email_address}"

      write.(claim, stream_name)
    end
```

We write to the User Email Address command stream, which then starts that process. You may be wondering why there's no idempotence protection within this event's handler. If the Registration component is stopped for whatever reason and reads the `Initiated`  event again, a second or third `Claim` message will be written.

That's okay because we *expect* commands to be written twice. The idempotence protection is already in place within the User Email Address component. It's unnecessary to have it here, too.

More importantly, there's no way for the *Registration component* to know whether a message was already sent to the User Email Address component. It has no access to the User Email Address component's entity stream or projections, so it cannot make decisions one way or another.

In any case, from the last essay we know we're expecting either a `Claimed` event to be written to the User Email Address entity stream or a `ClaimRejected` event.

```ruby
module Handlers
  module UserEmailAddress
    class Events
      include Log::Dependency
      include Messaging::Handle
      include Messaging::StreamName
      include Messages::Events

      dependency :write, Messaging::Postgres::Write
      dependency :clock, Clock::UTC
      dependency :store, Store

      def configure
        Messaging::Postgres::Write.configure(self)
        Clock::UTC.configure(self)
        Store.configure(self)
      end

      category :registration

      handle Claimed do |claimed|
        correlation_stream_name = claimed.metadata.correlation_stream_name
        registration_id = Messaging::StreamName.get_id(correlation_stream_name)

        registration, version = store.fetch(registration_id, include: :version)

        if registration.email_claimed?
          logger.info(tag: :ignored) { "Event ignored (Event: #{claimed.class.name}, Registration ID: #{registration_id}, Player ID: #{claimed.player_id})" }
          return
        end

        email_claimed = EmailClaimed.follow(claimed, exclude: [
          :encoded_email_address,
          :sequence
        ])
        email_claimed.registration_id = registration_id
        email_claimed.processed_time = clock.iso8601

        stream_name = stream_name(registration_id)

        write.(email_claimed, stream_name, expected_version: version)
      end

      handle ClaimRejected do |claim_rejected|
        correlation_stream_name = claim_rejected.metadata.correlation_stream_name
        registration_id = Messaging::StreamName.get_id(correlation_stream_name)

        registration, version = store.fetch(registration_id, include: :version)

        if registration.email_rejected?
          logger.info(tag: :ignored) { "Event ignored (Event: #{claim_rejected.class.name}, Registration ID: #{registration_id}, Player ID: #{claim_rejected.player_id})" }
          return
        end

        email_rejected = EmailRejected.follow(claim_rejected, exclude: [
          :encoded_email_address,
          :sequence
        ])
        email_rejected.registration_id = registration_id
        email_rejected.processed_time = clock.iso8601

        stream_name = stream_name(registration_id)

        write.(email_rejected, stream_name, expected_version: version)
      end
    end
  end
end
```

What's interesting here is the usage of the `correlation_stream_name`. Remember, when the correlation stream name was set in the `Initiated` event, any subsequent event written to any stream had the same correlation stream name copied over. We know that any `Claimed` or `ClaimRejected` event with a correlation stream name corresponding to the Registration stream originated within that component.

There may be any number of components and services interested in claiming email addresses, and we certainly don't want to read those into our Registration component. So this is how we know for certain we're only dealing with messages that originated within the Registration component.

The correlation stream name is also how we retrieve the `registration_id`. Remember that the email uniqueness component has no knowledge of user registrations. But because the correlation stream name within the messages' metadata is copied over from message to message, we can retrieve it here.

In both cases, we write an `EmailAccepted` and `EmailRejected`, respectively. This allows us to preserve idempotence, because now the Registration knows whether it read the `Claimed` or `ClaimRejected` event previously or not.

Once we have either one of those events, we can write a `Registered` or `Cancelled` event, thus ending the registration process.

```ruby
module Handlers
  class Events
    ## ...

    handle EmailAccepted do |email_accepted|
      registration_id = email_accepted.registration_id

      registration, version = store.fetch(registration_id, include: :version)

      if registration.registered?
        logger.info(tag: :ignored) { "Event ignored (Event: #{email_accepted.message_type}, Registration ID: #{registration_id}, User ID: #{email_accepted.user_id})" }
        return
      end

      time = clock.iso8601

      stream_name = stream_name(registration_id)

      registered = Registered.follow(email_accepted, exclude: [
        :claim_id,
        :time,
        :processed_time
      ])
      registered.time = time

      write.(registered, stream_name, expected_version: version)
    end

    handle EmailRejected do |email_rejected|
      registration_id = email_rejected.registration_id

      registration, version = store.fetch(registration_id, include: :version)

      if registration.cancelled?
        logger.info(tag: :ignored) { "Event ignored (Event: #{email_rejected.message_type}, Registration ID: #{registration_id}, User ID: #{email_rejected.user_id})" }
        return
      end

      time = clock.iso8601

      stream_name = stream_name(registration_id)

      cancelled = Cancelled.follow(email_rejected, exclude: [
        :claim_id,
        :time,
        :processed_time
      ])
      cancelled.time = time

      write.(cancelled, stream_name, expected_version: version)
    end
  end
end
```

With these in hand, we can inform the user that their registration was either successful or not. We may even be able to tell them the reason their registration failed was that their email address was already in use.

With the publish-subscribe pattern, you can imagine that we can take this even further. For example, a Welcome Email component could subscribe to any published `Registered` events and send onboarding emails to the user.

## Conclusion

The two components are now functionally complete. We have a user registration component that takes email uniqueness into account by communicating with a component created specifically for that purpose.

But how do we use these components in a web or native application? How do you paint pixels on a screen with an event sourced architecture?

That's what we'll talk about next month.
