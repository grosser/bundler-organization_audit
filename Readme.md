Audit all Gemfiles of a user/organization on Github for unpatched versions

    # simple
    gem install bundler-organization_audit

    # if you want --ignore-cve + last committer info
    git clone git://github.com/grosser/bundler-organization_audit.git
    cd bundler-organization_audit
    bundle
    cd `bundle show bundler-audit` && git submodule init && git submodule update && cd -
    bundle exec ./bin/bundle-organization-audit ... options ...

Usage
=====

### Public repos
For yourself (git config github.user)
```Bash
bundle-organization-audit
parallel
No Gemfile.lock found

parllel_tests
bundle-audit
No unpatched versions found

rails_example_app
bundle-audit
Name: rack
Version: 1.4.4
CVE: 2013-0263
Criticality: High
URL: http://osvdb.org/show/osvdb/89939
Title: Rack Rack::Session::Cookie Function Timing Attack Remote Code Execution
Patched Versions: ~> 1.1.6, ~> 1.2.8, ~> 1.3.10, ~> 1.4.5, >= 1.5.2

Vulnerable:
https://github.com/grosser/rails_example_app -- Peter Last Committer <peter@last-commit-email.com>
```

For someone elese
```Bash
bundle-organization-audit --user grosser
```

Ignore gems (ignores repos that have a %{repo}.gemspec)
```Bash
bundle-organization-audit --ignore-gems
```

For pipe -> only show vulnerable repos
```
bundle-organization-audit 2>/dev/null
```

Use for CI -> ignore old/unmaintained proejcts and unfixable/unimportant cves
```
bundle-organization-audit \
  --ignore https://github.com/xxx/a \
  --ignore https://github.com/xxx/b \
  --ignore-cve 2013-0269@1.5.3 \
  --ignore-cve '2013-0123@~>3.2.10' \
  --ignore-cve 2013-0234 \
  --organization xxx \
  --token yyy
```

Ignore cve

### Private repos

```Bash
# create a token that has access to your repositories
curl -v -u your-user-name -X POST https://api.github.com/authorizations --data '{"scopes":["repo"]}'
enter your password -> TOKEN

bundle-organization-audit --user your-user --token TOKEN --organization your-organization
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
