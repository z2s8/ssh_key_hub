# SSH Key Hub `version: pre-alpha!` [`api docs`](https://z2s8.github.io/ssh_key_hub/doc/top-level-namespace.html)
This project aims to make SSH Key management easier for teams, while introducing very little overhead.

## About
- SSH Key Hub **downloads** your team members' public SSH keys from multiple providers, **filters** them, then **outputs** the keys in a customizable format.
- It can run either on the remote server directly, or intergate with configuration management systems (such as *Ansible* and *Chef*) and ship the collected keys to servers efficently.
- This is a **lightweight tool**, it isn't an SSH server, it just prepares the user credentials for use with common SSH servers, such as *OpenSSH*.

## Example run

### Using the DSL

```ruby
require 'ssh_key_hub'
require 'ssh_key_hub/dsl'

Keys.new do
  # get keys from gitlab:
  gitlab group: 'gitlab-org', project: 'gitlab-ce', private_token: ENV['GITLAB_TOKEN']
  
  # get keys from github and then filter these keys only:
  github org: 'namewip', access_token: ENV['GITHUB_TOKEN'] do
    reject_weak
  end

  # export all keys regardless of origin:
  export
end
```

### Using the lower level API

```ruby
require_relative 'ssh_key_hub'

creds = SSHKeyHub::Provider::GitHub.new(access_token: ENV['GITHUB_TOKEN']).keys_for_org_team 'namewip', 'Owners'
=> {"z2s8"=>
  <SortedSet: {"ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCxY1j...Mn2zd", # RSA 1024
               "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDEVFI...2JQ=="} # RSA 4096
             >}

Processor::KeysFilter.new(creds).reject_weak
=> {"z2s8"=>
  <SortedSet: {"ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDEVFI...2JQ=="} # RSA 4096
             >}
```

## Current providers
- **GitHub:** _whole organization_, _organization team_
- **GitLab:** _whole group_, _group project_
- _and more coming!_

## ToDo
- Add exporters
- Add tests
- Package as gem
- Create docker image
- Improve docs
