---
title: My Ruby Development Environment
date: 2021-02-12 08:00:00 -0600
author: joseph
---

When I come into a new Ruby project, whether that be through a new job or contract work or open source project, each one will generally follow the same principles, in that they'll use the same package manager, they'll have a `Gemfile` to note dependencies, and so forth.

But I want to avoid polluting my own local gems with those from whatever project I'm working on. Each project's configuration may be unique and require dependencies that are unique to their project. Installing gems to the local system can cause problems in other projects. What I want is to **control** my project's dependencies without needing to rely on external tools.

Here's how I do that.

## Credit

I want to note that most of these scripts below come from Eventide's own [repositories](https://github.com/eventide-project). Be sure to check them out!

## Local Installation

When I install gems, I make sure to install with the following command:

```bash
bundle install --standalone --path=./gems
```

Let's start with the second option, `--path=./gems`, which installs the gems into the directory specified, which in this case is the `gems` directory. Some might install gems into the `vendor` directory, which is a little confusing to me. Gems go in the `gems` directory, which means there is no confusion.

The `--standalone` option obviates the need for `rubygems` or `bundler` at runtime by generating a `gems/bundler/setup.rb` file. Here's an example of a file generated:

```ruby
# gems/bundler/setup.rb

require 'rbconfig'
ruby_engine = RUBY_ENGINE
ruby_version = RbConfig::CONFIG["ruby_version"]
path = File.expand_path('..', __FILE__)
$:.unshift "#{path}/"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/evt-virtual-2.0.1.0/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/rack-2.2.3/lib"
$:.unshift "#{path}/../../lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/test_bench-fixture-1.3.1.1/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/test_bench-1.2.0.5/lib"
```

What this does is add each gem location to the `$LOAD_PATH` array so that these gems can be loaded more easily with the `require` keyword.

## What about RVM Gemsets?

I don't really use RVM in my own Ruby workflow, mostly because working with RVM is a bit of a faff. But I also don't like that the gems are installed to some obscure hidden directory. Much better, in my opinion, to install them in the project directory, as close to the code as possible.

## Ignoring Files

With a single command, we've generated two directories, `.bundle/` and `gems/`. We don't actually want to check these into the project, so we add them to our `.gitignore` file:

```ruby
# .gitignore

.bundle/
gems
```

But now we have changes to the `.gitignore` file. Do we check that in?

## My Personal Local Branch

Note: I'm assuming you use `git` in your own workflow.

Personally, I only make structural changes like this to a project I have control over. If I'm just one contributor among many, then I have less say to shake things up. So, instead I build my own local branch and push changes in the following manner.

First, let's make our own local branch:

```bash
git checkout -b local-build
```

We now have our own local branch that diverges from the `master` branch. I then add the following file:

```ruby
# load_path.rb

bundler_standalone_loader = 'gems/bundler/setup'

begin
  require_relative bundler_standalone_loader
rescue LoadError
  warn "WARNING: Standalone bundle loader is not at #{bundler_standalone_loader}. Using Bundler to load gems."
  require "bundler/setup"
  Bundler.setup
end
```

This file will load the standalone bundle file we generated earlier. Otherwise, it will load the gems via Bundler.

Then, we need to add the following to our `config/application.rb` file, if we're in a Rails project:

```ruby
# config/application.rb

require_relative '../load_path'
require_relative 'boot'
```

This will reference the earlier `load_path.rb` file. Then, we can run the Rails application as normal, without the need for Bundler.

```bash
bin/rails server
```

Finally, I'll commit all the changes I've made into a single commit:

```bash
git commit -m "Local build"
```

This includes the `.gitignore`, `load_path.rb`, and `config/application.rb` files.

## Development

During the normal course of development, I'll make commits to my `local-build` branch and then move them to a branch that I can push to the remote repository. Remember that other people might not have our structural changes from the `local-build` branch, so we want to avoid affecting downstream users.

After I'm done making whatever commits I need for the feature, I'll do the following:

```bash
git checkout master
git pull
git checkout -b new-feature
git cherry-pick <commit-sha>
git push -u origin new-feature
```

I want to get the latest changes from `master` before pushing my own changes, which is why I'm pulling from the `master` branch. Then, I make a new branch for the feature and cherry-pick the commits I need from my `local-build` branch.

Finally, I push my branch to the remote repository.

## Updating My Local Branch

I don't want my `local-build` branch to remain out of date with the changes in `master`, so I'll simply rebase my local branch with `master`.

```bash
git checkout master
git pull
git checkout local-build
git rebase master
```

By doing this, I make sure that my own changes, especially that "Local Build" commit, don't become buried in newer changes from other contributors.

## Conclusion

The main reason I do this though is so I keep gems and dependencies isolated to their local project directory, especially if I'm working in a project I don't have much control over. This is *especially* useful when I'm working on multiple such projects and need to keep dependencies separate from one another.

It's a bit more complicated and may not work for everyone. But having control over my gems is important enough for me to do the extra work.
