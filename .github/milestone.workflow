workflow "On Milestone" {
  on = "milestone"
  resolves = ["Create Release Notes"]
}

action "Create Release Notes" {
  uses = "mmornati/release-notes-generator-action@master"
  secrets = ["GITHUB_TOKEN"]
}
