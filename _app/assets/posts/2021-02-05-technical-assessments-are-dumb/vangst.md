# Goal

Write a Ruby library that allows qualified job seekers to apply for a job with a fixed number of workers needed, typically less than 100. Assume there are many applicants and they are quick to apply, within seconds of the job posting. There could be hundreds of people applying at once to a job that accepts less than 100 workers. If a job needs N number of workers and N people apply, no more candidates can apply and an error is produced.

Assume Postgres is available to you. Either utilize Postgres in your solution or create a mock/dummy object with comments on what each function would do, like this:

```ruby
module Database
  def insert_application
    # This function should have thorough comments and can return stubbed values
    # The comments could include SQL statements you would expect to run
  end
end
```

Focus your energy on the core logic to accomplish this task. The library does not need to use Rails nor be accessible to the web, but using Rails is acceptable. It would be best to build this logic into a small library as if it were to be used in a Rails application and/or model behavior the way you would in your ideal Rails app.

Finally, write a short script to exercise your code. However you'd like to exercise your code is up to you, but this should be an executable Ruby script that can be run on the command line. Your program should output some details about its execution, like a report of the number of successful/failed applications.

## Expectations

Try to time-box the exercise to 2-3 hours. Keep this constraint in mind as you work, it's very possible that certain items don't get finished, try to save a few minutes to summarize your efforts in a readme or email if this is the case.

## Requirements

- Model entities/attributes you would typically persist to a database
- Model job/application system
- Build an executable Ruby program
- Provide instructions on how to run your program
- Use a recent stable version of Ruby MRI
- Leverage Git, and demonstrate your workflow / style via commits
- Ensure there are tests included:
  - RSpec
  - test-unit
  - minitest
- Email your solution as a .zip package to mike.pack@vangst.com, include 'Software Engineer Take-Home'

## Evaluation

The qualities we're looking for are:
- Clarity: is the code organized and structured well, is it easy to read and comprehend?
- Maintainability:: if it had to be updated / extended how easy would that be?
- Testability: are the tests comprehensive and covering the appropriate use cases?

## Questions

If you have questions about the instructions, please ask. We want you to be successful. If you have a question about how to handle something that wasn't specifically addressed, make a decision and feel free to call it out in your readme or email with your reasoning behind your decision. No right or wrong answers for these types of things.
