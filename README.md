# Nidobata

`nidobata` command reads stdin and posts it into idobata.io.

![selection_553](https://cloud.githubusercontent.com/assets/43346/21834741/10668980-d7fb-11e6-9852-b587950e3982.png)

Chat: [idobata/oss](https://idobata.io/#/organization/idobata/room/oss)

## Installation

    $ gem install nidobata

## Usage

```
$ nidobata init
Email: hibariya@example.com
Password: ⏎
$ uname -a | nidobata post my-org-slug my-room
```

`--pre` option surrounds input with `<pre></pre>`.

```
$ cat README.md | nidobata post my-org-slug my-room --pre
```

`--syntax` option surronds input with triple tildes(`~~~`) with syntax name.
:warning: It does not work when including triple backquotes or triple tildes in input text :warning:

```
$ cat lib/nidobata/version.rb | nidobata post my-org-slug my-room --syntax ruby
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/idobata/nidobata. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

