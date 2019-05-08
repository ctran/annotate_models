workflow "Build, Test, and Publish" {
  resolves = "Publish"
  on = "push"
}

# Filter for a new tag
action "Tag" {
  uses = "actions/bin/filter@master"
  args = "tag v*"
}

action "Build" {
  needs = "Tag"
  uses = "scarhand/actions-ruby@master"
  args = "build *.gemspec"
}

action "Publish" {
  needs = "Build"
  uses = "scarhand/actions-ruby@master"
  args = "push *.gem"
  secrets = ["RUBYGEMS_AUTH_TOKEN"]
}

workflow "On Milestone" {
  on = "milestone"
  resolves = ["Create Release Notes"]
}

action "Create Release Notes" {
  uses = "mmornati/release-notes-generator-action@master"
  secrets = ["GITHUB_TOKEN"]
}
