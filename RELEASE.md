## Prerequisite 

- Install "git-flow" (`brew install git-flow`)
- Install "bump" gem (`gem install bump`)


## Perform a release

- `git flow release start <release>`
- Update the `CHANGELOG.md` file
- `bump current`
- `bump patch`
- `rm -rf dist`
- `rake spec`
- `rake gem`
- `git flow release finish <release>`

- `rake gem:publish`

