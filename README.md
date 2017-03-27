# Recluse

**Recluse** is a web crawler meant to ease quality assurance. Currently, it has three crawling tests:

- **Status**—checks the [HTTP status codes](https://en.wikipedia.org/wiki/List_of_HTTP_status_codes) of links on the site. Good for detecting broken links.
- **Find**—finds pages with links matching the pattern. Good for ensuring that references to a page are removed or renamed.
- **Assert**—checks pages for the existence of HTML elements. Good for asserting that things are consistent across pages.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'recluse'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install recluse

## Profiles

Recluse depends on creating profiles for your sites. This way, the configuration can be reusable for frequent quality assurance checks. Profiles are saved as YAML files (.yaml) in `~/.recluse/` and have the following format:

```yaml
---
name: profile_name
roots:
- http://example.com/
- http://anotherroot.biz/subdir
email: email@domain.com
blacklist:
- http://example.com/dontgohere/*
whitelist:
- http://example.com/dontgohere/unlessitshere/*
internal_only: false
scheme_squash: false
redirect: false
```

### Profile options

| Name | Required | Type | Default | Description |
|------|----------|------|---------|-------------|
| name | Yes | String | | The name of your profile for identification. Should also match the filename (i.e., `site` has filename `site.yaml`). |
| roots | Yes | Array of URLs | | The roots to start from for spidering. Will spider all subdirectories and files. |
| email | Yes | String | | Your email. This is for identification of who is crawling a web page in case a system administrator has issues with it. |
| blacklist | No | Array of globs | Empty array | [Glob patterns](https://en.wikipedia.org/wiki/Glob_(programming)) of sites not to spider. Useful to keep Recluse focused only on the important stuff. | 
| whitelist | No | Array of globs | Empty array | [Glob patterns](https://en.wikipedia.org/wiki/Glob_(programming)) of sites to spider, even if they are blacklisted. |
| internal_only | No | Boolean | `false` | If true, Recluse will not follow external links. If false, it will follow for the **status** mode. |
| scheme_squash | No | Boolean | `false` | Treats "http" URLs the same as "https". This way, Recluse will not redundantly spider secure and nonsecure duplicates of the same page. |
| redirect | No | Boolean | `false` | Follow the redirect to the resulting page if true. |

## Use

After installation, the `recluse` executable should be available for your command line.

### Tests

#### Status

Spiders through the profile and reports the [HTTP status codes](https://en.wikipedia.org/wiki/List_of_HTTP_status_codes) of the links. If the profile is not internal only, external links will also have their statuses checked.

	$ recluse status csv_path profile1 [profile2] ... [options]

| Argument | Alias | Required | Type | Default | Description |
|----------|-------|----------|------|---------|-------------|
| csv_path | | Yes | String | | The path of where to save results. Results are saved as CSV (comma-separated values). |
| profiles | | Yes | Array of profile names | | List of profiles to check. More than one profile can be checked in one run. |
| group_by | `--group-by`<br/>`-g` | No | One of `none` or `url` | `none` | What to group by in the result output. If `none`, there will be a row for each pair of checked URL and the page it was found on. If `url`, there will be one row for each URL, and the page cell will have a list of every page the URL was found on. |
| include | `--include`<br/>`-i` | No | Array of status codes | Include all | Include these status codes in the results. Can be a specific number (ex: `200`) or a wildcard (ex: `2xx`). You can also include `idk` for pages that result in errors that prevent status code detection. |
| exclude | `--exclude`<br/>`-x` | No | Array of status codes | Exclude none | Exclude these status codes from the results. Same format as including. |

##### Output format

```csv
Status code,URL,On page,With error
```

#### Find

Spiders through the profiles and checks if a link matching one of the provided patterns is found. Will only go over internal pages.

	$ recluse find csv_path profile1 [profile2] ... --globs pattern1 [pattern2] ... [options]

| Argument | Alias | Required | Type | Default | Description |
|----------|-------|----------|------|---------|-------------|
| csv_path | | Yes | String | | The path of where to save results. Results are saved as CSV (comma-separated values). |
| profiles | | Yes | Array of profile names | | List of profiles to check. More than one profile can be checked in one run. |
| globs | `--globs`<br/>`-G` | Yes | Array of globs | | [Glob patterns](https://en.wikipedia.org/wiki/Glob_(programming)) to find as URLs of links on the page. |
| group_by | `--group-by`<br/>`-g` | No | One of `none`, `url`, or `page` | `none` | What to group by in the result output. If `none`, there will be a row for each pair of checked URL and the page it was found on. If `url`, there will be one row for each URL, and the page cell will have a list of every page the URL was found on. If `page`, there will be one row for each page, and the URL cell will list every matching URL found on the page. |

##### Output format

###### Group by `none` or `url`

```csv
Matching URLs,Pages
```

###### Group by `page`

```csv
Page,Matching URLs
```

#### Assert

Asserts the existence of an HTML element using [CSS-style selectors](https://developer.mozilla.org/en-US/docs/Web/Guide/CSS/Getting_started/Selectors). Will only check internal pages.

	$ recluse assert csv_path profile1 [profile2] ... --exists selector1 [selector2] ...
	
| Argument | Alias | Required | Type | Default | Description |
|----------|-------|----------|------|---------|-------------|
| csv_path | | Yes | String | | The path of where to save results. Results are saved as CSV (comma-separated values). |
| profiles | | Yes | Array of profile names | | List of profiles to check. More than one profile can be checked in one run. |
| true | `--true`<br/>`--report-true-only` | No | Boolean | `false` | Report only true assertions. Reports both true and false assertions by default. |
| false | `--false`<br/>`--report-false-only` | No | Boolean | `false` | Report only false assertions. Reports both true and false assertions by default. |
| exists | `--exists`<br/>`-e` | Yes | Array of CSS selectors | | CSS selectors to assert the existence of on each spidered page. |

##### Output format

```csv
Selector,Exists,On page
```

### Profile management

#### Where

Path where the profiles are stored for manual edits.

	$ recluse where

#### Creation

Create a profile.

	$ recluse profile create [options] name email root1 [root2] ...
	
For further description of the arguments, check the **Profile options** section.

| Argument | Alias | Required | Type | Default |
|----------|-------|----------|------|---------|
| name | | Yes | String | |
| email | | Yes | String | |
| roots | | Yes | Array of strings | |
| blacklist | `--blacklist` | No | Array of globs | Empty array |
| whitelist | `--whitelist` | No | Array of globs | Empty array |
| internal_only | `--internal_only`<br/>`--no-internal-only` | No | Boolean | `false` |
| scheme_squash | `--scheme-squash`<br/>`--no-scheme-squash` | No | Boolean | `false` |
| redirect | `--redirect`<br/>`--no-redirect` | No | Boolean | `false` |

#### Edit

Edit profile options. Any option not provided will stay as it was.

	$ recluse profile edit name [options]
	
| Argument | Alias | Required | Type |
|----------|-------|----------|------|
| name | | Yes | String |
| email | `--email` | No | String |
| roots | `--roots` | No | Array of strings |
| blacklist | `--blacklist` | No | Array of globs |
| whitelist | `--whitelist` | No | Array of globs |
| internal_only | `--internal_only`<br/>`--no-internal-only` | No | Boolean |
| scheme_squash | `--scheme-squash`<br/>`--no-scheme-squash` | No | Boolean |
| redirect | `--redirect`<br/>`--no-redirect` | No | Boolean |

##### Blacklist, whitelist, and roots

More powerful blacklist and whitelist editing. All examples are interchangeable between the three list types. However, if the profile has no roots, it will not run.

###### Add

Add patterns/roots to the profile's list.

	$ recluse profile blacklist add name new_thing1 [new_thing2] ...

###### Remove

Remove patterns/roots from the profile's list.

	$ recluse profile blacklist remove name thing1 [thing2] ...
	
###### Clear

Remove all patterns/roots from the profile's list.

	$ recluse profile blacklist clear name

###### List

List the patterns/roots in the profile's list.

	$ recluse profile blacklist list name

#### Remove

Delete a profile.

	$ recluse profile remove name

#### Rename

Rename a profile.

	$ recluse profile rename old_name new_name

#### List

List all profiles.

	$ recluse profile list

#### Info

List the YAML info of the profile.

	$ recluse profile info name

## Contributing

Bug reports and pull requests are welcome on GitHub.

## Extending

Recluse is modular so you can add tasks if you want. Below is an example of adding your own task to Recluse.

```ruby
require 'recluse'

module MyModule
  ##
  # Create a task object
  class MyTask < Recluse::Tasks::Task
    ##
    # First argument must be the profile. The rest are hash arguments specific for the task.
    def initialize(profile, option1: false, option2: true, results: nil)
      # Sets up everything based on the profile, queue-specific options, and can also prepopulate results.
      super(profile, queue_options, results: results)
      @queue.run_if do |link|
      	# Run a link if this function returns true.
      	# Link is a Recluse::Link object.
      end
      @queue.on_complete do |link, response|
        # Run this function after the page has either successfully been retrieved, or failed to be retrieved.
        # Link is a Recluse::Link object.
        # Response is a Recluse::Response object.
      end
    end
  end
end

# Add your task to the task list under the key 'my_task'.
Recluse::Tasks.add_task(:my_task, MyModule::MyTask)

# You can now access 'my_task' like you would the default Recluse tasks.
my_profile = Recluse::Profile.load('my_profile')
my_profile.test(:my_task, option1: true, option2: true)
results = my_profile.results[:my_task]
```

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

