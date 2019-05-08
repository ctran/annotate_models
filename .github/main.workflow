workflow "Build, Test, and Publish" {
  on = "push"
  resolves = ["Publish"]
}

action "Build" {
  uses = "scarhand/actions-ruby@master"
  args = "build *.gemspec"
}

# Filter for a new tag
action "Tag" {
  needs = "Build"
  uses = "actions/bin/filter@master"
  args = "tag v*"
}

action "Publish" {
  needs = "Tag"
  uses = "scarhand/actions-ruby@master"
  args = "push *.gem"
  secrets = ["RUBYGEMS_AUTH_TOKEN"]
}
