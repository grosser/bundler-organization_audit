Audit all Gemfiles of a user/organization on github for unpatched versions

Install
=======

    gem install bundler-organization_audit

Usage
=====

### Public repos

```Bash
bundle-authorization-audit # for yourself (git config github.user)
parllel: safe
parllel_tests: safe
rails_example_app:
Name: rack
Version: 1.4.4
CVE: 2013-0263
Criticality: High
URL: http://osvdb.org/show/osvdb/89939
Title: Rack Rack::Session::Cookie Function Timing Attack Remote Code Execution
Patched Versions: ~> 1.1.6, ~> 1.2.8, ~> 1.3.10, ~> 1.4.5, >= 1.5.2

bundle-authorization-audit --user grosser # for someone elese
...

```

### Private repos

```Bash
# create a token that has access to your repositories
curl -v -u your-user-name -X POST https://api.github.com/authorizations --data '{"scopes":["repo"]}'
enter your password -> you get a TOKEN

bundle-authorization-audit --token TOKEN

bundle-authorization-audit --token TOKEN --user your-organization-name
...
```

Dev
===
 - test private repo fetching via `cp spec/private{.example,}.yml` and filling it out

Author
======
[Michael Grosser](http://grosser.it)<br/>
michael@grosser.it<br/>
License: MIT<br/>
[![Build Status](https://travis-ci.org/grosser/bundler-organization_audit.png)](https://travis-ci.org/grosser/bundler-organization_audit)
