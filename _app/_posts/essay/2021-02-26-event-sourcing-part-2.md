---
title: "Event Sourcing, Part 2: Email Uniqueness"
date: 2021-02-26 08:00:00 -0600
author: joseph
---

> **Note:** Be sure to check out my 11+ hour video tutorial on [event sourcing]({% post_url video/2021-07-02-event-sourcing-tutorial  %})!

Last month I discussed how to build a component that accepted [user registrations]({% post_url /essay/2021-01-29-event-sourcing-part-1 %}). We learned about the basic building blocks of an Eventide component, including entities, messages, projections, and handlers.

But that component remained incomplete, as it didn't take email uniqueness into account. We'll be discussing all that and more today, with actual code examples.

## Disclaimer

This essay is a tool for learning. It is always a bad idea to copy and paste code you found on the Internet without considering the implications each line of code would have on your own systems. You are the custodian of your codebase after all, which is why I continue to hammer that point home essay after essay.

## Email Uniqueness

Previously, the registration component processed `Register` commands and wrote `Registered` events to the message store. You can see the tuples from a sample message store below.

```
-[ RECORD 1 ]---+----------------------------------------------------------------------------------------------------------------------------------------------------------------
global_position | 1
position        | 0
stream_name     | registration:command-abc
type            | Register
data            | {"time": "2000-01-01T00:00:00.001Z", "userId": "123", "emailAddress": "john@example.com", "registrationId": "abc"}
-[ RECORD 2 ]---+----------------------------------------------------------------------------------------------------------------------------------------------------------------
global_position | 2
position        | 0
stream_name     | registration-abc
type            | Registered
data            | {"time": "2000-01-01T00:00:00.001Z", "userId": "123", "emailAddress": "john@example.com", "processedTime": "2021-02-15T11:02:18.314Z", "registrationId": "abc"}
```

The `registration-abc` stream holds all of the events for the entity Registration of ID `abc`. But there's no way to know whether an email address was already reserved unless we have an entity tied to the email address that we can fetch.

This means we need a separate entity and therefore a separate component that keeps track of email uniqueness.

## The User Email Address Entity

Like before, a good place to start developing a component is with the entity.

```ruby
class UserEmailAddress
  include Schema::DataStructure

  attribute :encoded_email_address, String
  attribute :email_address, String
  attribute :user_id, String
  attribute :claimed_time, Time
  attribute :sequence, Integer

  def claimed?
    !claimed_time.nil?
  end

  def processed?(message_sequence)
    return false if sequence.nil?

    sequence >= message_sequence
  end
end
```

The `encoded_email_address` attribute here is much like the ID attribute in the previous component's entity. We use it as the stream's ID so that it is coupled to the email address and not some arbitrary UUID. The reason we use an encoded email address is because email addresses are case insensitive. For example, the email addresses `john@example.com` and `JOHN@example.com` are equivalent, so we need to make sure that we normalize the casing of any email addresses inputted into our system.

Here's how we might encode an email address:

```ruby
def encode_email_address(email_address)
  downcased_email_address = email_address.downcase
  Digest::SHA256.hexdigest(downcased_email_address)
end
```

The reason I've included a SHA256 hashing function is a little bit outside the scope of this essay, but are security-related and have to do with not allowing user inputs to be used as stream IDs, outside of well-structured schemas like UUIDs. Suffice to say that you should always validate user inputs before allowing such data into your system.

In any case, the entity is much the same as the last one, with a few additions. We have an `email_address` and an associated `user_id`. We have a `claimed_time` attribute and a `claimed?` predicate, which will be used to determine whether a user has already claimed a specified email address.

But we also have a `sequence` attribute and a `processed?` predicate, which we haven't seen before. We'll go into more depth when we discuss the handler.

## Messages

Each component is designed with different considerations in mind and part of that is giving each thing their proper name.

```ruby
class Claim
  include Messaging::Message

  attribute :claim_id, String
  attribute :encoded_email_address, String
  attribute :email_address, String
  attribute :user_id, String
  attribute :time, String
end

class ClaimRejected
  include Messaging::Message

  attribute :claim_id, String
  attribute :encoded_email_address, String
  attribute :email_address, String
  attribute :user_id, String
  attribute :time, String
  attribute :sequence, Integer
end

class Claimed
  include Messaging::Message

  attribute :claim_id, String
  attribute :encoded_email_address, String
  attribute :email_address, String
  attribute :user_id, String
  attribute :time, String
  attribute :processed_time, String
  attribute :sequence, Integer
end
```

Unlike before, we have three messages, one command and two events. Each `Claim` command message, when processed, needs to fetch the current state of the entity. If the entity or email address is already claimed, then the current `Claim` is rejected, resulting in a `ClaimRejected` event being written. Otherwise, a `Claimed` event is written.

Additionally, there is a `claim_id` attribute here, which we'll discuss more down below.

## Projection

With two events to apply, we can see our projection for this component is just a little bit more complicated, though of course all we're really doing is copying data from the event to the entity.

```ruby
class Projection
  include EntityProjection
  include Messages::Events

  entity_name :user_email_address

  apply Claimed do |claimed|
    user_email_address.encoded_email_address = claimed.encoded_email_address
    user_email_address.email_address = claimed.email_address
    user_email_address.user_id = claimed.user_id
    user_email_address.sequence = claimed.sequence
    user_email_address.claimed_time = Clock.parse(claimed.time)
  end

  apply ClaimRejected do |claim_rejected|
    user_email_address.sequence = claim_rejected.sequence
  end
end
```

Note that the entity's sequence is being set with each event's sequence.

## Handler(s)

Let's take a look at the handler.

```ruby
module Handlers
  class Commands
    include Log::Dependency
    include Messaging::Handle
    include Messaging::StreamName
    include Messages::Commands
    include Messages::Events

    dependency :write, Messaging::Postgres::Write
    dependency :clock, Clock::UTC
    dependency :store, Store

    def configure
      Messaging::Postgres::Write.configure(self)
      Clock::UTC.configure(self)
      Store.configure(self)
    end

    category :user_email_address

    handle Claim do |claim|
      transaction_stream_name = stream_name(claim.claim_id, 'userEmailAddressTransaction')

      claim = Claim.follow(claim)

      Try.(MessageStore::ExpectedVersion::Error) do
        write.initial(claim, transaction_stream_name)
      end
    end
  end
end
```

That doesn't quite look like the handler from last time. That's because there's a crucial difference between the Registration component and this component.

With the Registration component, there is the expectation that each Registration entity will have only one `Register` command and therefore one `Registered` event. With our idempotent protections in place, each subsequent `Register` command is ignored, with no event written in such a case.

However, with our email uniqueness component, we must potentially process an infinite number of `Claim` commands through the lifetime of the email address, and each command must output either a `Claimed` event or a `ClaimRejected` event. And yet, we must still protect against duplicate command messages, otherwise our component will not be idempotent.

To do this we use two different streams, a command stream and a transactional stream. The above handler is processing messages from the command stream, and to make sure duplicate command messages are not processed, we write to the transactional stream in a special way.

We take the `claim_id` from the command message and write a copy of the `Claim` command to the `userEmailAddressTransaction-{claim_id}` stream using the `write.initial` method. This method is a convenience method that is equivalent to the following:

```ruby
write.(claim, transaction_stream_name, expected_version: -1)
```

This makes sure that any message we write to the specified stream is on an empty stream, i.e. a stream with zero messages. If the writer attempts to write a message to a non-empty stream, the `Try` module will suppress the `MessageStore::ExpectedVersion::Error` exception that was raised, allowing the component to process the next message in the category.

Once the `Claim` command is written to the transactional stream, we have a second handler that will read *those* messages and write events to the component's event stream.

```ruby
module Handlers
  class Commands
    class Transactions
      include Log::Dependency
      include Messaging::Handle
      include Messaging::StreamName
      include Messages::Commands
      include Messages::Events

      dependency :write, Messaging::Postgres::Write
      dependency :clock, Clock::UTC
      dependency :store, Store

      def configure
        Messaging::Postgres::Write.configure(self)
        Clock::UTC.configure(self)
        Store.configure(self)
      end

      category :user_email_address

      handle Claim do |claim|
        encoded_email_address = claim.encoded_email_address

        user_email_address, version = store.fetch(encoded_email_address, include: :version)

        sequence = claim.metadata.global_position

        if user_email_address.processed?(sequence)
          logger.info(tag: :ignored) { "Command ignored (Command: #{claim.message_type}, User Email Address: #{user_email_address.email_address}, User Email Address Sequence: #{user_email_address.sequence}, Claim Sequence: #{sequence})" }
          return
        end

        time = clock.iso8601

        stream_name = stream_name(encoded_email_address)

        if user_email_address.claimed?
          claim_rejected = ClaimRejected.follow(claim)
          claim_rejected.time = time
          claim_rejected.sequence = sequence

          write.(claim_rejected, stream_name, expected_version: version)

          return
        end

        claimed = Claimed.follow(claim)
        claimed.processed_time = time
        claimed.sequence = sequence

        write.(claimed, stream_name, expected_version: version)
      end
    end
  end
end
```

This looks a lot more like the Registration component's handler. First, we use the entity's `processed?` predicate to make sure we didn't already process the message. As a reminder, here's the `processed?` predicate.

```ruby
class UserEmailAddress
  include Schema::DataStructure

  ## ...
  attribute :sequence, Integer

  ## ...

  def processed?(message_sequence)
    return false if sequence.nil?

    sequence >= message_sequence
  end
end
```

We've taken the message's `sequence`, which is the command message's global position within the message store, and compared it to the entity's `sequence`. If a message was already processed, then the entity's `sequence` will be higher than the message's `sequence`. If the entity's `sequence` is `nil`, then it hasn't processed any messages from the transactional stream.

We know this because when we fetch the entity from the `store` object, we're applying the following events:

```ruby
class Projection
  ## ...

  apply Claimed do |claimed|
    ## ...
    user_email_address.sequence = claimed.sequence
    ## ...
  end

  apply ClaimRejected do |claim_rejected|
    user_email_address.sequence = claim_rejected.sequence
  end
end
```

Each event has a `sequence` that was taken from the corresponding command's global position.

If the predicate `processed?` returns `true`, we know we have already processed that message and can safely ignore it, thus ensuring idempotence.

## Decisions, Decisions

Next in the handler is an important bit of business logic.

```ruby
module Handlers
  class Commands
    class Transactions
      ## ...

      handle Claim do |claim|
        encoded_email_address = claim.encoded_email_address

        user_email_address, version = store.fetch(encoded_email_address, include: :version)

        ## ...

        time = clock.iso8601

        stream_name = stream_name(encoded_email_address)

        if user_email_address.claimed?
          claim_rejected = ClaimRejected.follow(claim)
          claim_rejected.time = time
          claim_rejected.sequence = sequence

          write.(claim_rejected, stream_name, expected_version: version)

          return
        end

        claimed = Claimed.follow(claim)
        claimed.processed_time = time
        claimed.sequence = sequence

        write.(claimed, stream_name, expected_version: version)
      end
    end
  end
end
```

Once we've determined whether a message was already processed or not, we need to check whether the specified email address was claimed or not. This is where the `claimed?` predicate comes in. As I mentioned before, depending on the results of that predicate, we write different events, either `Claimed` or `ClaimRejected`.

We now have a reliable way to ensure email uniqueness.

## Conclusion

By this point, we have written two separate components, one to accept user registrations and another to ensure email uniqueness. We've made our components idempotent with two separate patterns and protected against concurrent writes.

However, we're *still* not done. The Registration component itself doesn't take email uniqueness into account, as that's taken care of by the component we just wrote. What we need to do is to update the Registration component so that it can send and receive messages to and from the User Email Address component.

Which is what we'll talk about next time.
